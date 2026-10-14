import importlib.util
import pathlib
import unittest


SCRIPT_PATH = pathlib.Path(__file__).with_name("ImportInstructorGougeWorkbook.py")
SPEC = importlib.util.spec_from_file_location("instructor_gouge_importer", SCRIPT_PATH)
IMPORTER = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(IMPORTER)


class InstructorGougeImportTests(unittest.TestCase):
    def test_repair_preserves_representative_character_sequences(self):
        sample = "with students will first mistake questions system switching"
        self.assertEqual(IMPORTER.repair_instructor_review_text(sample), sample)

    def test_repair_handles_known_source_fragments(self):
        sample = "inructors ll help udents th the syem and stch radios; re keen and mo relaxed"
        self.assertEqual(
            IMPORTER.repair_instructor_review_text(sample),
            "instructors will help students with the system and switch radios; more keen and most relaxed",
        )


if __name__ == "__main__":
    unittest.main()
