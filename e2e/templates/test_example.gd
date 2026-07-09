extends Node

# Fixture for the Testing/QA block (run_automated_tests).

func test_always_passes():
	return true

func test_math():
	return 2 + 2 == 4
