-- Migration: Document Versioned Response Format
-- Date: 2024-12-19
-- Description: This migration documents the new versioned response format for test process forms.
--              No schema changes are needed as we use JSONB columns which are flexible.
--              This migration serves as documentation for the expected data structure.

-- ============================================================================
-- VERSIONED RESPONSE FORMAT
-- ============================================================================
--
-- The initial_questions, mid_term_questions, and exit_interview columns
-- now store data in a versioned format to track which questions were answered:
--
-- {
--   "questionnaire_version": "1.0",
--   "completed_at": "2024-12-19T10:30:00Z",
--   "responses": [
--     {
--       "question_id": "initial_checklist_setup_time",
--       "question_version": 1,
--       "question_text": "How long did it take to set up your custom checklist?",
--       "answer": "5 minutes",
--       "answered_at": "2024-12-19T10:30:00Z"
--     },
--     ...
--   ]
-- }
--
-- Benefits:
-- 1. Each response is tied to the exact question text that was shown
-- 2. Question versions allow tracking changes to questions over time
-- 3. Easy to identify which questions were answered even if questions change
-- 4. Backward compatible - old flat format responses still work
-- 5. Future-proof for adding new questions or modifying existing ones
--
-- ============================================================================
-- BACKWARD COMPATIBILITY
-- ============================================================================
--
-- Old format (still supported):
-- {
--   "checklist_setup_time": "5 minutes",
--   "checklist_purpose": "morning routine",
--   ...
-- }
--
-- New format (preferred):
-- {
--   "questionnaire_version": "1.0",
--   "completed_at": "2024-12-19T10:30:00Z",
--   "responses": [...]
-- }
--
-- The application layer handles both formats seamlessly.
--
-- ============================================================================
-- QUESTION DEFINITIONS
-- ============================================================================
--
-- All questions are defined in the codebase at:
-- src/lib/questionDefinitions.ts
--
-- Each question has:
-- - id: Unique identifier (e.g., "initial_checklist_setup_time")
-- - version: Version number for tracking changes
-- - text: The actual question text shown to users
-- - type: Field type (text, textarea, select, scale, etc.)
-- - required: Whether the field is mandatory
-- - options: Available options for select/radio fields
-- - placeholder: Hint text for text inputs
--
-- To modify questions:
-- 1. Update the question text in questionDefinitions.ts
-- 2. Increment the version number
-- 3. Old responses will still reference the exact question that was asked
--
-- ============================================================================
-- LOCALSTORAGE PERSISTENCE
-- ============================================================================
--
-- Form data is automatically saved to browser localStorage as users type.
-- Storage key format: fokusuhr_form_{test_process_id}_{form_type}
--
-- This allows users to:
-- - Close their browser and resume later
-- - Refresh the page without losing progress
-- - Work on forms over multiple sessions
--
-- Storage is cleared automatically when a form is successfully submitted.
--
-- ============================================================================

-- Add a comment to the test_processes table to document the new format
COMMENT ON COLUMN public.test_processes.initial_questions IS 
'Initial questions responses in versioned format. See migration 20251219000000 for details.';

COMMENT ON COLUMN public.test_processes.mid_term_questions IS 
'Mid-term questions responses in versioned format. See migration 20251219000000 for details.';

COMMENT ON COLUMN public.test_processes.exit_interview IS 
'Exit interview responses in versioned format. See migration 20251219000000 for details.';

-- Create a helper function to check if a response is in the new versioned format
CREATE OR REPLACE FUNCTION public.is_versioned_response(response jsonb)
RETURNS boolean
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT 
    response IS NOT NULL AND
    response ? 'questionnaire_version' AND
    response ? 'responses' AND
    jsonb_typeof(response -> 'responses') = 'array';
$$;

COMMENT ON FUNCTION public.is_versioned_response IS 
'Helper function to check if a form response is in the new versioned format';

-- Example queries:
-- 
-- Get all test processes with versioned initial questions:
-- SELECT id, initial_questions 
-- FROM test_processes 
-- WHERE is_versioned_response(initial_questions);
--
-- Get all test processes with legacy format initial questions:
-- SELECT id, initial_questions 
-- FROM test_processes 
-- WHERE initial_questions IS NOT NULL 
-- AND NOT is_versioned_response(initial_questions);
--
-- Extract specific question response from versioned format:
-- SELECT id, 
--   (
--     SELECT r->>'answer' 
--     FROM jsonb_array_elements(initial_questions->'responses') r
--     WHERE r->>'question_id' = 'initial_checklist_setup_time'
--   ) as checklist_setup_time
-- FROM test_processes
-- WHERE is_versioned_response(initial_questions);

