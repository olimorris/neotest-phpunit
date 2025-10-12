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
            line = 13,
            message = [[ExampleTest::test_that_false_is_true
Failed asserting that false is true.

/Users/Oli/Code/Projects/neotest-phpunit/tests/Unit/ExampleTest.php:14]],
          },
        },
        output_file = "/tmp/nvimhYaIPj/3",
        short = [[ExampleTest::test_that_false_is_true
Failed asserting that false is true.

/Users/Oli/Code/Projects/neotest-phpunit/tests/Unit/ExampleTest.php:14]],
        status = "failed",
      },
    }

    assert.are.same(utils.get_test_results(xml_output, output_file), expected)
  end)

  it("parses multiple files", function()
    local output_file = "/tmp/nvimhYaIPj/3"
    local xml_output = {
      testsuites = {
        testsuite = {
          _attr = {
            assertions = "18",
            errors = "0",
            failures = "1",
            name = "",
            skipped = "0",
            tests = "8",
            time = "0.001904",
            warnings = "0",
          },
          testsuite = {
            {
              _attr = {
                assertions = "2",
                errors = "0",
                failures = "1",
                name = "Unit",
                skipped = "0",
                tests = "2",
                time = "0.001233",
                warnings = "0",
              },
              testsuite = {
                _attr = {
                  assertions = "2",
                  errors = "0",
                  failures = "1",
                  file = "/Users/Oli/Code/Projects/neotest-phpunit/tests/Unit/ExampleTest.php",
                  name = "ExampleTest",
                  skipped = "0",
                  tests = "2",
                  time = "0.001233",
                  warnings = "0",
                },
                testcase = {
                  {
                    _attr = {
                      assertions = "1",
                      class = "ExampleTest",
                      classname = "ExampleTest",
                      file = "/Users/Oli/Code/Projects/neotest-phpunit/tests/Unit/ExampleTest.php",
                      line = "7",
                      name = "test_that_true_is_true",
                      time = "0.001027",
                    },
                  },
                  {
                    _attr = {
                      assertions = "1",
                      class = "ExampleTest",
                      classname = "ExampleTest",
                      file = "/Users/Oli/Code/Projects/neotest-phpunit/tests/Unit/ExampleTest.php",
                      line = "13",
                      name = "this_should_fail",
                      time = "0.000207",
                    },
                    failure = {
                      [[ExampleTest::this_should_fail
Failed asserting that false is true.

/Users/Oli/Code/Projects/neotest-phpunit/tests/Unit/ExampleTest.php:15]],
                      _attr = {
                        type = "PHPUnit\\Framework\\ExpectationFailedException",
                      },
                    },
                  },
                },
              },
            },
            {
              _attr = {
                assertions = "16",
                errors = "0",
                failures = "0",
                name = "Examples",
                skipped = "0",
                tests = "6",
                time = "0.000671",
                warnings = "0",
              },
              testsuite = {
                {
                  _attr = {
                    assertions = "15",
                    errors = "0",
                    failures = "0",
                    file = "/Users/Oli/Code/Projects/neotest-phpunit/tests/Examples/UserTest.php",
                    name = "TestProject\\UserTest",
                    skipped = "0",
                    tests = "5",
                    time = "0.000646",
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
                        time = "0.000145",
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
                        time = "0.000143",
                      },
                    },
                    {
                      _attr = {
                        assertions = "2",
                        class = "TestProject\\UserTest",
                        classname = "TestProject.UserTest",
                        file = "/Users/Oli/Code/Projects/neotest-phpunit/tests/Examples/UserTest.php",
                        line = "30",
                        name = "testTellAge",
                        time = "0.000026",
                      },
                    },
                    {
                      _attr = {
                        assertions = "3",
                        class = "TestProject\\UserTest",
                        classname = "TestProject.UserTest",
                        file = "/Users/Oli/Code/Projects/neotest-phpunit/tests/Examples/UserTest.php",
                        line = "38",
                        name = "testAddFavoriteMovie",
                        time = "0.000149",
                      },
                    },
                    {
                      _attr = {
                        assertions = "5",
                        class = "TestProject\\UserTest",
                        classname = "TestProject.UserTest",
                        file = "/Users/Oli/Code/Projects/neotest-phpunit/tests/Examples/UserTest.php",
                        line = "47",
                        name = "testRemoveFavoriteMovie",
                        time = "0.000183",
                      },
                    },
                  },
                },
                {
                  _attr = {
                    assertions = "1",
                    errors = "0",
                    failures = "0",
                    file = "/Users/Oli/Code/Projects/neotest-phpunit/tests/Examples/some/deep/nesting/NestingTest.php",
                    name = "NestingTest",
                    skipped = "0",
                    tests = "1",
                    time = "0.000025",
                    warnings = "0",
                  },
                  testcase = {
                    _attr = {
                      assertions = "1",
                      class = "NestingTest",
                      classname = "NestingTest",
                      file = "/Users/Oli/Code/Projects/neotest-phpunit/tests/Examples/some/deep/nesting/NestingTest.php",
                      line = "7",
                      name = "test_something_that_is_true",
                      time = "0.000025",
                    },
                  },
                },
              },
            },
          },
        },
      },
    }

    local expected = {
      ["/Users/Oli/Code/Projects/neotest-phpunit/tests/Examples/UserTest.php::13"] = {
        output_file = "/tmp/nvimhYaIPj/3",
        short = [[TESTPROJECT.USERTEST
-> PASSED - testClassConstructor]],
        status = "passed",
      },
      ["/Users/Oli/Code/Projects/neotest-phpunit/tests/Examples/UserTest.php::22"] = {
        output_file = "/tmp/nvimhYaIPj/3",
        short = [[TESTPROJECT.USERTEST
-> PASSED - testTellName]],
        status = "passed",
      },
      ["/Users/Oli/Code/Projects/neotest-phpunit/tests/Examples/UserTest.php::30"] = {
        output_file = "/tmp/nvimhYaIPj/3",
        short = [[TESTPROJECT.USERTEST
-> PASSED - testTellAge]],
        status = "passed",
      },
      ["/Users/Oli/Code/Projects/neotest-phpunit/tests/Examples/UserTest.php::38"] = {
        output_file = "/tmp/nvimhYaIPj/3",
        short = [[TESTPROJECT.USERTEST
-> PASSED - testAddFavoriteMovie]],
        status = "passed",
      },
      ["/Users/Oli/Code/Projects/neotest-phpunit/tests/Examples/UserTest.php::47"] = {
        output_file = "/tmp/nvimhYaIPj/3",
        short = [[TESTPROJECT.USERTEST
-> PASSED - testRemoveFavoriteMovie]],
        status = "passed",
      },
      ["/Users/Oli/Code/Projects/neotest-phpunit/tests/Examples/some/deep/nesting/NestingTest.php::7"] = {
        output_file = "/tmp/nvimhYaIPj/3",
        short = [[NESTINGTEST
-> PASSED - test_something_that_is_true]],
        status = "passed",
      },
      ["/Users/Oli/Code/Projects/neotest-phpunit/tests/Unit/ExampleTest.php::13"] = {
        errors = {
          {
            line = 14,
            message = [[ExampleTest::this_should_fail
Failed asserting that false is true.

/Users/Oli/Code/Projects/neotest-phpunit/tests/Unit/ExampleTest.php:15]],
          },
        },
        output_file = "/tmp/nvimhYaIPj/3",
        short = [[ExampleTest::this_should_fail
Failed asserting that false is true.

/Users/Oli/Code/Projects/neotest-phpunit/tests/Unit/ExampleTest.php:15]],
        status = "failed",
      },
      ["/Users/Oli/Code/Projects/neotest-phpunit/tests/Unit/ExampleTest.php::7"] = {
        output_file = "/tmp/nvimhYaIPj/3",
        short = [[EXAMPLETEST
-> PASSED - test_that_true_is_true]],
        status = "passed",
      },
    }

    assert.are.same(utils.get_test_results(xml_output, output_file), expected)
  end)

  it("parses PHPUnit 11 error output correctly", function()
    local output_file = "/tmp/phpunit11-output.xml"
    local xml_output = {
      testsuites = {
        testsuite = {
          _attr = {
            assertions = "2",
            errors = "1",
            failures = "0",
            file = "/path/to/tests/Unit/ExampleTest.php",
            name = "ExampleTest",
            skipped = "0",
            tests = "2",
            time = "0.005",
            warnings = "0",
          },
          testcase = {
            {
              _attr = {
                assertions = "1",
                class = "ExampleTest",
                classname = "ExampleTest",
                file = "/path/to/tests/Unit/ExampleTest.php",
                line = "10",
                name = "test_example_passes",
                time = "0.001",
              },
            },
            {
              _attr = {
                assertions = "1",
                class = "ExampleTest",
                classname = "ExampleTest",
                file = "/path/to/tests/Unit/ExampleTest.php",
                line = "15",
                name = "test_example_fails",
                time = "0.002",
              },
              error = {
                [[ExampleTest::test_example_fails
ErrorException: Undefined property: App\Models\User::$middleName

/path/to/vendor/laravel/framework/src/Illuminate/Foundation/Bootstrap/HandleExceptions.php:258
/path/to/tests/Unit/ExampleTest.php:20]],
                _attr = {
                  type = "ErrorException",
                },
              },
            },
          },
        },
      },
    }

    local expected = {
      ["/path/to/tests/Unit/ExampleTest.php::10"] = {
        output_file = "/tmp/phpunit11-output.xml",
        short = [[EXAMPLETEST
-> PASSED - test_example_passes]],
        status = "passed",
      },
      ["/path/to/tests/Unit/ExampleTest.php::15"] = {
        errors = {
          {
            line = 19,
            message = [[ExampleTest::test_example_fails
ErrorException: Undefined property: App\Models\User::$middleName

/path/to/vendor/laravel/framework/src/Illuminate/Foundation/Bootstrap/HandleExceptions.php:258
/path/to/tests/Unit/ExampleTest.php:20]],
          },
        },
        output_file = "/tmp/phpunit11-output.xml",
        short = [[ExampleTest::test_example_fails
ErrorException: Undefined property: App\Models\User::$middleName

/path/to/vendor/laravel/framework/src/Illuminate/Foundation/Bootstrap/HandleExceptions.php:258
/path/to/tests/Unit/ExampleTest.php:20]],
        status = "failed",
      },
    }

    assert.are.same(utils.get_test_results(xml_output, output_file), expected)
  end)
end)
