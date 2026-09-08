#!/usr/bin/env python3
"""Tests for scripts/dotviewer-gen-utis.py metadata overrides.

These tests protect the round-trip guarantee for exported UTIs that carry
extra conformance parents or MIME tags in `dotViewer/project.yml` — running
`dotviewer-gen-utis.py --apply` must never silently drop them.

Run:
    python3 scripts/tests/test_gen_utis_overrides.py
"""

from __future__ import annotations

import importlib.util
import io
import sys
import unittest
from contextlib import redirect_stdout
from pathlib import Path

SCRIPT_PATH = Path(__file__).resolve().parents[1] / "dotviewer-gen-utis.py"


def _load_module():
    spec = importlib.util.spec_from_file_location("dv_gen_utis", SCRIPT_PATH)
    assert spec and spec.loader, f"cannot load {SCRIPT_PATH}"
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class TestApplyMetadataOverrides(unittest.TestCase):
    def setUp(self):
        self.mod = _load_module()

    def test_gpx_gets_public_xml_and_mime(self):
        conforms, mimes = self.mod.apply_metadata_overrides(
            "com.stianlars1.dotviewer.gpx",
            ["public.plain-text"],
        )
        self.assertIn("public.xml", conforms)
        self.assertIn("public.plain-text", conforms)
        self.assertEqual(conforms.index("public.xml"),
                         conforms.index("public.plain-text") - 1,
                         "public.xml must come before public.plain-text")
        self.assertEqual(mimes, ["application/gpx+xml"])

    def test_unknown_identifier_is_pass_through(self):
        conforms, mimes = self.mod.apply_metadata_overrides(
            "com.stianlars1.dotviewer.does-not-exist",
            ["public.plain-text"],
        )
        self.assertEqual(conforms, ["public.plain-text"])
        self.assertEqual(mimes, [])

    def test_override_does_not_mutate_input(self):
        original = ["public.plain-text"]
        self.mod.apply_metadata_overrides(
            "com.stianlars1.dotviewer.gpx", original,
        )
        self.assertEqual(original, ["public.plain-text"])

    def test_override_dedupes_when_already_present(self):
        conforms, _ = self.mod.apply_metadata_overrides(
            "com.stianlars1.dotviewer.gpx",
            ["public.xml", "public.plain-text"],
        )
        self.assertEqual(conforms.count("public.xml"), 1)


class TestBuildExport(unittest.TestCase):
    """Guards the assembled export dict for the gpx UTI."""

    def setUp(self):
        self.mod = _load_module()

    def test_gpx_export_carries_xml_and_mime(self):
        exp = self.mod.build_export(
            "gpx",
            "com.stianlars1.dotviewer.gpx",
            {"lang": "xml", "display": "GPS Exchange Format (XML)"},
        )
        self.assertEqual(exp["ext"], "gpx")
        self.assertEqual(exp["identifier"], "com.stianlars1.dotviewer.gpx")
        self.assertIn("public.xml", exp["conforms_to"])
        self.assertIn("public.plain-text", exp["conforms_to"])
        self.assertEqual(exp["mime_types"], ["application/gpx+xml"])

    def test_export_without_override_has_no_mime(self):
        exp = self.mod.build_export(
            "example",
            "com.stianlars1.dotviewer.example",
            {"lang": "python", "display": "Example"},
        )
        self.assertEqual(exp["mime_types"], [])
        # public source-code language → source-code + plain-text parents.
        self.assertEqual(exp["conforms_to"],
                         ["public.source-code", "public.plain-text"])


class TestProjectYmlRoundTrip(unittest.TestCase):
    """Guards project.yml against silent metadata loss on --apply."""

    def test_gpx_block_in_project_yml_matches_overrides(self):
        project_yml = SCRIPT_PATH.resolve().parent.parent / "dotViewer" / "project.yml"
        text = project_yml.read_text(encoding="utf-8")
        # Locate the UTExportedTypeDeclarations entry for the gpx UTI and pull
        # the surrounding block. The declaration starts with a stable prefix.
        marker = "- UTTypeIdentifier: com.stianlars1.dotviewer.gpx"
        idx = text.find(marker)
        self.assertNotEqual(idx, -1, "gpx UTI declaration missing from project.yml")
        block = text[idx:idx + 600]
        self.assertIn("public.xml", block,
                      "project.yml gpx block must declare public.xml conformance")
        self.assertIn("application/gpx+xml", block,
                      "project.yml gpx block must declare application/gpx+xml MIME")


if __name__ == "__main__":
    # Silence the "Resolving UTIs via macOS UTType API..." chatter if a test
    # accidentally triggers main(); tests only touch pure functions and file IO.
    with redirect_stdout(io.StringIO()):
        pass
    unittest.main(verbosity=2)
