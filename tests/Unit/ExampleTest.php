<?php

use PHPUnit\Framework\TestCase;

class ExampleTest extends TestCase
{
    public function test_that_true_is_true()
    {
        $this->assertTrue(true);
    }

    /** @test */
    public function test_this_should_fail()
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
}
