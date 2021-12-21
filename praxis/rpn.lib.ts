// -----------------------------------------------------------------------------
// ** Message

// A string intended for output.
//
// https://stackoverflow.com/questions/55155151/haskells-newtypes-in-typescript
type Message = string & { readonly Message: unique symbol };

function errorMessage(s: Readonly<string>): Message {
  return "ERROR: " + s as Message;
}

// -----------------------------------------------------------------------------
// ** BinOp

type BinOp =
  | "+"
  | "-"
  | "*"
  | "/";

export function parseBinOp(s: Readonly<string>): BinOp | undefined {
  log("parseBinOp: " + s);
  if (s === "+") {
    return s;
  }
  if (s === "-") {
    return s;
  }
  if (s === "*") {
    return s;
  }
  if (s === "/") {
    return s;
  }
  return undefined;
}

// -----------------------------------------------------------------------------
// ** Program

type Program = Array<number | BinOp>;

// -----------------------------------------------------------------------------
// *** Parsing

type Tokens = Array<string>;

// pre: no newlines
function tokenize(s: string): Tokens {
  console.assert(!s.includes("\n"));
  return s.split(" ");
}

export const PARSE_ERROR_BAD_TOKEN = "Bad token, not one of +, -, *, /";
export type ParseError = {
  err: typeof PARSE_ERROR_BAD_TOKEN;
  prog: Program;
  rest: Tokens;
};

function showParseError(err: ParseError): Message {
  return errorMessage(err.err);
}

function parseToken(
  tok: Readonly<string>,
): BinOp | number | typeof PARSE_ERROR_BAD_TOKEN {
  log("parseToken: " + tok);
  const op = parseBinOp(tok);
  if (op !== undefined) {
    return op;
  }
  log("parseFloat: " + tok);
  const int = parseFloat(tok);
  if (!isNaN(int)) {
    return int;
  }
  return PARSE_ERROR_BAD_TOKEN;
}

// pre: no newlines
export function parseProgram(s: Readonly<string>): Program | ParseError {
  const tokens = tokenize(s);
  log("parseProgram: [" + tokens.toString() + "]");
  const prog: Program = [];
  while (true) {
    const top = tokens.shift();
    if (top === undefined) {
      break;
    }
    const tok = parseToken(top);
    if (tok === PARSE_ERROR_BAD_TOKEN) {
      return { err: tok, rest: tokens, prog: prog };
    }
    prog.push(tok);
  }
  return prog;
}

// -----------------------------------------------------------------------------
// *** Evaluation

type Stack = Array<number>;

export const EVAL_ERROR_BINOP_STACK = "Just a binop on the stack.";
export const EVAL_ERROR_EMPTY_STACK = "Empty stack!";
export type EvalError =
  | { err: typeof EVAL_ERROR_BINOP_STACK; binOp: BinOp }
  | { err: typeof EVAL_ERROR_EMPTY_STACK; prog: Program };

function showEvalError(e: Readonly<EvalError>): Message {
  return errorMessage(e.err);
}

type Step = {
  readonly prog: Program;
  readonly stack: Stack;
};

function evaluateBinOp(
  binOp: Readonly<BinOp>,
  op1: Readonly<number>,
  op2: Readonly<number>,
): number {
  if (binOp === "+") {
    return op1 + op2;
  }
  if (binOp === "-") {
    return op1 - op2;
  }
  if (binOp === "*") {
    return op1 * op2;
  }
  if (binOp === "/") {
    return op1 / op2;
  }
  console.assert(false);
  return 0;
}

function showStep(s: Readonly<Step>): string {
  return "step{[" + s.prog.toString() + "], [" + s.stack.toString() + "]}";
}

// NB: Mutates fields of argument
function step(s: Readonly<Step>): EvalError | undefined {
  log("step: " + showStep(s));
  const top = s.prog.shift();
  if (top === undefined) {
    return undefined;
  }
  if (typeof top === "string") {
    const op1 = s.stack.shift();
    const op2 = s.stack.shift();
    if (op1 === undefined || op2 === undefined) {
      s.prog.unshift(top);
      return { err: EVAL_ERROR_EMPTY_STACK, prog: s.prog };
    }
    s.stack.unshift(evaluateBinOp(top, op2, op1));
    return undefined;
  }
  s.stack.unshift(top);
  return undefined;
}

// NB: Mutates argument
export function evaluate(prog: Program): number | EvalError {
  const s: Readonly<Step> = { prog: prog, stack: [] };
  log("eval: " + showStep(s));
  while (s.prog.length > 0) {
    const err = step(s);
    if (err !== undefined) {
      return err;
    }
  }
  const top = s.stack.shift();
  if (top !== undefined) {
    log("done: " + String(top));
    return top;
  }
  return { err: EVAL_ERROR_EMPTY_STACK, prog: s.prog };
}

// -----------------------------------------------------------------------------
// ** I/O

// -----------------------------------------------------------------------------
// *** Printing and Reading

// NB: Makes a copy of its input
async function _print(s: Readonly<Message>): Promise<void> {
  await Deno.stdout.write(new TextEncoder().encode(String(s)));
}

// NB: Makes a copy of its input
async function printLine(s: Readonly<Message>): Promise<void> {
  console.assert(!s.endsWith("\n"));
  // TODO(lb): why doesn't this work?
  // await print(s + "\n" as Message);
  await console.log(s);
}

// TODO(lb): How do exceptions work? How can this fail?
async function read(): Promise<string> {
  const SIZE = 1024;
  const buf = new Uint8Array(SIZE);
  const decoder = new TextDecoder();
  let bytesRead: number | null = 1;
  let str = "";
  while (true) {
    bytesRead = await Deno.stdin.read(buf);
    if (bytesRead === null) {
      log("null");
      break;
    }
    if (bytesRead === 0) {
      log("zero");
      break;
    }
    log("size: " + bytesRead);
    let bufStr = decoder.decode(buf);
    // Weird: Have to manually remove all trailing null bytes
    bufStr = bufStr.replace(/\0+$/, "");
    log("read: " + bufStr.trim());
    str = str + bufStr;
  }
  return str;
}

async function readLines(): Promise<Array<string>> {
  const data = await read();
  log("data: " + data.trim());
  return data.split("\n");
}

// -----------------------------------------------------------------------------
// *** Logging

const DEBUG = Deno.env.get("DEBUG") === "1";

async function log(s: Readonly<string>) {
  if (DEBUG) {
    await printLine("[DEBUG] " + s as Message);
  }
}

// -----------------------------------------------------------------------------
// *** Main

async function realMain(): Promise<void> {
  log("main");
  let exit = 0;
  const lines = await readLines();
  log("lines: " + lines);
  while (true) {
    const line = lines.shift();
    if (line === undefined || line === "") {
      break;
    }
    log("line: " + line);
    const prog = parseProgram(line);
    log("prog: " + prog);
    if (!Array.isArray(prog)) {
      await printLine(showParseError(prog));
      exit = 1;
      continue;
    }
    const result = evaluate(prog);
    log("done: " + result);
    if (typeof result !== "number") {
      await printLine(showEvalError(result));
      exit = 1;
      continue;
    }
    await printLine(String(result.toFixed(2)) as Message);
  }
  log("exit: " + String(exit));
  Deno.exit(exit);
}

export async function main(): Promise<void> {
  log("main");
  try {
    realMain();
  } catch (error) {
    await printLine(error);
  }
}

export {};
