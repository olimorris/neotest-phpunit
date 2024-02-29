<?php

use PHPUnit\Framework\TestCase;
use PHPUnit\Framework\Attributes\Test;

class ExampleTest extends TestCase
{
    public function test_that_true_is_true()
    {
        $this->assertTrue(true);
    }

    public function test_that_true_is_true_again()
    {
        $this->assertTrue(true);
    }

    /** @test */
    public function test_this_should_fail()
    {
        $this->assertTrue(false);
    }

    /** @test */
    public function test_this_should_fail_also()
    {
        $this->assertTrue(false);
    }

    /** @test */
    public function this_should_fail_as_well()
    {
        $this->assertTrue(false);
    }

    public function this_should_not_run()
    {
        $this->assertTrue(true);
    }

	public function this_test_should_not_run_also()
	{
		$this->assertTrue(true);
	}

	#[Test]
	public function this_test_should_run()
	{
		$this->assertTrue(true);
	}

    /**
     * @dataProvider myProvider
     */
    public function testWithDataProvider(bool $val): void
    {
        $this->assertTrue($val);
    }

    public function myProvider(): array
    {
        return [
            'set one'  => [true],
            'set two' => [false],
        ];
    }
}
