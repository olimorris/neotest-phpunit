<?php

use PHPUnit\Framework\TestCase;

class ExampleTest extends TestCase
{
    public function test_that_true_is_true()
    {
       $this->assertTrue(true);
    }

    public function test_that_false_is_true()
    {
        $this->assertTrue(false);
    }
}
