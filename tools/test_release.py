"""Tests of the release tools. Run: python -m unittest discover -s tools -p "test_*.py"."""
import re
import tempfile
import unittest
import zipfile
from pathlib import Path
from unittest.mock import patch

import package
import release


class ReleaseNotesTests(unittest.TestCase):
    def notes(self, changelog, version):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "CHANGELOG.md").write_text(changelog, encoding="utf-8")
            with patch.object(release, "ROOT", root):
                return release.notes(version)

    def test_release_does_not_use_prerelease_notes(self):
        text = "## 1.8.2-beta1\nBeta notes.\n\n## 1.8.2\nRelease notes.\n"
        self.assertEqual(self.notes(text, "1.8.2"), "Release notes.\n")

    def test_missing_release_is_not_satisfied_by_prerelease(self):
        with self.assertRaises(SystemExit):
            self.notes("## 1.8.2-beta1\nBeta notes.\n", "1.8.2")

    def test_heading_title_and_following_section(self):
        text = "## 1.8.2 - Fixes\nThe fix.\n\n## 1.8.1\nOlder notes.\n"
        self.assertEqual(self.notes(text, "1.8.2"), "The fix.\n")

    def test_explicit_prerelease(self):
        text = "## 1.8.2-beta1\nBeta notes.\n\n## 1.8.1\nOlder notes.\n"
        self.assertEqual(self.notes(text, "1.8.2-beta1"), "Beta notes.\n")

    def test_this_version_has_notes(self):
        self.assertTrue(release.notes().strip())

    def test_release_types(self):
        self.assertEqual([release.release_type(v) for v in ("1.0.0", "1.1.0-beta1", "1.1.0-alpha2", "1.1.0-rc1")],
                         ["release", "beta", "alpha", "beta"])


class PackageTests(unittest.TestCase):
    def test_zip(self):
        with tempfile.TemporaryDirectory() as directory:
            out = package.build(directory)
            with zipfile.ZipFile(out) as z:
                names = z.namelist()
                toc_bytes = z.read("SimpleRogueHelperForever/SimpleRogueHelperForever.toc")
        toc = toc_bytes.decode("utf-8")
        version = release.version()
        self.assertEqual(out.name, f"SimpleRogueHelperForever-{version}.zip")
        # One folder, the addon's, with slashes only
        self.assertTrue(all(n.startswith("SimpleRogueHelperForever/") for n in names), names)
        self.assertFalse([n for n in names if "\\" in n])
        # Every file the TOC lists (its backslashes as slashes), and the rest the game needs
        listed = [l.strip().replace("\\", "/") for l in toc.splitlines() if l.strip() and not l.startswith("#")]
        for f in listed + ["Bindings.xml", "LICENSE", "README.md", "CHANGELOG.md"]:
            self.assertIn("SimpleRogueHelperForever/" + f, names)
        # Nothing of the tests, tools, docs or the repository's own
        self.assertFalse([n for n in names if re.search(r"/(tests|tools|docs|dist|\.github|\.claude)/|/\.git", n)], names)
        self.assertEqual(toc_bytes, (package.ROOT / "SimpleRogueHelperForever.toc").read_bytes())


if __name__ == "__main__":
    unittest.main()
