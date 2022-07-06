local utils = require("neotest-phpunit.utils")

describe("get_test_results", function()
  it("parses output when testing a method", function()
    local output_file = "/tmp/nvimhYaIPj/3"
    local xml_output = {
      testsuites = {
        testsuite = {
          _attr = {
            assertions = "1",
            errors = "0",
            failures = "0",
            file = "/Users/Oli/Code/Projects/neotest-phpunit/tests/Unit/ExampleTest.php",
            name = "ExampleTest",
            skipped = "0",
            tests = "1",
            time = "0.002292",
            warnings = "0",
          },
          testcase = {
            _attr = {
              assertions = "1",
              class = "ExampleTest",
              classname = "ExampleTest",
              file = "/Users/Oli/Code/Projects/neotest-phpunit/tests/Unit/ExampleTest.php",
              line = "7",
              name = "test_that_true_is_true",
              time = "0.002292",
            },
          },
        },
      },
    }

    local expected = {
      ["/Users/Oli/Code/Projects/neotest-phpunit/tests/Unit/ExampleTest.php::7"] = {
        ["output_file"] = "/tmp/nvimhYaIPj/3",
        ["short"] = [[EXAMPLETEST
-> PASSED - test_that_true_is_true]],
        ["status"] = "passed",
      },
    }

    assert.are.same(utils.get_test_results(xml_output, output_file), expected)
  end)

  it("parses output when testing a file", function()
    local output_file = "/tmp/nvimhYaIPj/3"
    local xml_output = {
      testsuites = {
        testsuite = {
          _attr = {
            assertions = "2",
            errors = "0",
            failures = "0",
            file = "/Users/Oli/Code/Projects/neotest-phpunit/tests/Examples/UserTest.php",
            name = "TestProject\\UserTest",
            skipped = "0",
            tests = "2",
            time = "0.001525",
            warnings = "0",
          },
          testcase = {
            {
              _attr = {
                assertions = "3",
                class = "TestProject\\UserTest",
                classname = "TestProject.UserTest",
                file = "/Users/Oli/Code/Projects/neotest-phpunit/tests/Examples/UserTest.php",
                line = "13",
                name = "testClassConstructor",
                time = "0.000949",
              },
            },
            {
              _attr = {
                assertions = "2",
                class = "TestProject\\UserTest",
                classname = "TestProject.UserTest",
                file = "/Users/Oli/Code/Projects/neotest-phpunit/tests/Examples/UserTest.php",
                line = "22",
                name = "testTellName",
                time = "0.000135",
              },
            },
          },
        },
      },
    }

    local expected = {
      ["/Users/Oli/Code/Projects/neotest-phpunit/tests/Examples/UserTest.php::13"] = {
        ["output_file"] = "/tmp/nvimhYaIPj/3",
        ["short"] = [[TESTPROJECT.USERTEST
-> PASSED - testClassConstructor]],
        ["status"] = "passed",
      },
      ["/Users/Oli/Code/Projects/neotest-phpunit/tests/Examples/UserTest.php::22"] = {
        ["output_file"] = "/tmp/nvimhYaIPj/3",
        ["short"] = [[TESTPROJECT.USERTEST
-> PASSED - testTellName]],
        ["status"] = "passed",
      },
    }

    assert.are.same(utils.get_test_results(xml_output, output_file), expected)
  end)

  it("parses a file even if there is a failure", function()
    local output_file = "/tmp/nvimhYaIPj/3"
    local xml_output = {
      testsuites = {
        testsuite = {
          _attr = {
            assertions = "2",
            errors = "0",
            failures = "1",
            file = "/Users/Oli/Code/Projects/neotest-phpunit/tests/Unit/ExampleTest.php",
            name = "ExampleTest",
            skipped = "0",
            tests = "2",
            time = "0.001008",
            warnings = "0",
          },
          testcase = {
            {
              _attr = {
                assertions = "1",
                class = "ExampleTest",
                classname = "ExampleTest",
                file = "/Users/Oli/Code/Projects/neotest-phpunit/tests/Unit/ExampleTest.php",
                line = "12",
                name = "test_that_false_is_true",
                time = "0.000141",
              },
              failure = {
                [[ExampleTest::test_that_false_is_true
Failed asserting that false is true.

/Users/Oli/Code/Projects/neotest-phpunit/tests/Unit/ExampleTest.php:14]],
                _attr = {
                  type = "PHPUnit\\Framework\\ExpectationFailedException",
                },
              },
            },
          },
        },
      },
    }

    local expected = {
      ["/Users/Oli/Code/Projects/neotest-phpunit/tests/Unit/ExampleTest.php::12"] = {
        errors = {
          {
            line = "12",
          },
        },
        output_file = "/tmp/nvimhYaIPj/3",
        status = "failed",
      },
    }

    assert.are.same(utils.get_test_results(xml_output, output_file), expected)
  end)
end)
