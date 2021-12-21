import { assertEquals } from "https://Deno.land/std/testing/asserts.ts";
import * as lib from "./rpn.lib.ts";

function eq<T, U>(val1: T, val2: U, msg: string) {
  // TODO(lb): this is unhelpful (prints [Object object]). Why?
  // @ts-ignore: generics
  // if (val1 !== val2) {
  //   console.log("val1: " + val1);
  //   console.log("val2: " + val2);
  // }
  assertEquals(val1, val2, msg);
}

Deno.test("parseBinOp", () => {
  eq(lib.parseBinOp("+"), "+", "+");
  eq(lib.parseBinOp("*"), "*", "*");
  eq(lib.parseBinOp("_"), undefined, "_");
});

Deno.test("parseProgram", () => {
  eq(lib.parseProgram("0"), [0], "0");
  eq(lib.parseProgram("0 0"), [0, 0], "0 0");
  eq(lib.parseProgram("0 0 +"), [0, 0, "+"], "0 0 +");
});

Deno.test("evaluate", () => {
  eq(lib.evaluate([]), { err: lib.EVAL_ERROR_EMPTY_STACK, prog: [] }, "[]");
  eq(lib.evaluate(["+"]), {
    err: lib.EVAL_ERROR_EMPTY_STACK,
    prog: ["+"],
  }, "[+]");
  eq(lib.evaluate([0]), 0, "[0]");
  eq(lib.evaluate([0, 0, "+"]), 0, "[0,0,+]");
  eq(lib.evaluate([0, 1, "+"]), 1, "[0,1,+]");
  eq(lib.evaluate([3, 4, "-"]), -1, "[3,4,-]");
  eq(lib.evaluate([3, 4, "-", 5, "+"]), 4, "[3,4,-,5,+]");
  eq(lib.evaluate([3, 4, 5, "*", "-"]), -17, "[3,4,5,*,+]");
});
