package com.example;

import junit.framework.Test;
import junit.framework.TestCase;

public class LibTest extends TestCase {
    public void testHello() {
        assertTrue( "Hello world".equals(Lib.hello("world")) );
    }
}
