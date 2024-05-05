<?php

use PHPUnit\Framework\Attributes\Test;
use PHPUnit\Framework\TestCase;

class AttributeTest extends TestCase
{
    #[Test]
    public function it_should_pass_if_attributes_work()
    {
        $this->assertTrue(true);
    }
}
