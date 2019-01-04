#!/usr/bin/env python3

# Copyright 2014-2017 Jiří Janoušek <janousek.jiri@gmail.com>
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import re
import sys
from collections import OrderedDict

import pyparsing as pp


class Node:
    pass


class Namespace(Node):
    def __init__(self, name, members):
        super().__init__()
        self.name = name
        self.members = members

    def __repr__(self):
        buf = ["<Namespace %s" % self.name]
        if self.members:
            for member in self.members:
                buf.extend(indent(member))
        buf.append("\n>")
        return "".join(buf)

class Class(Node):
    def __init__(self, name, access, parent=None, abstract=False, interfaces=None, anotations=None, methods=None, constructors=None):
        super().__init__()
        self.name = name
        self.access = access
        self.members = {}
        self.parent = parent
        self.interfaces = interfaces
        self.anotations = anotations
        self.abstract = abstract
        self.constructors = constructors
        self.methods = methods

    def __repr__(self):
        buf = ["<Class %s" % self.name]
        if self.parent:
            buf.append(":%s" % self.parent)
        if self.access:
            buf.append(", %s" % self.access)
        if self.abstract:
            buf.append(", abstract")
        if self.anotations:
            buf.extend(indent(self.anotations))
        if self.constructors:
            for item in self.constructors:
                buf.extend(indent(item))
        if self.methods:
            for item in self.methods:
                buf.extend(indent(item))
        buf.append("\n>")
        return "".join(buf)


class Method(Node):
    def __init__(self, name, access, parent=None, rtype=None, params=None, throws=None, override=False, abstract=False, anotations=None, is_async=False):
        super().__init__()
        self.name = name
        self.access = access
        self.parent = parent
        self.rtype = rtype
        self.params = params
        self.throws = throws
        self.override = override
        self.abstract = abstract
        self.anotations = anotations
        self.is_async = is_async

    def __repr__(self):
        buf = ["<Method %s -> %s" % (self.name, self.rtype)]
        if self.access:
            buf.append(", %s" % self.access)
        if self.abstract:
            buf.append(", abstract")
        if self.is_async:
            buf.append(", async")
        if self.override:
            buf.append(", override")
        if self.throws:
            buf.append(", throws %s" % " ".join(self.throws))
        if self.anotations:
            buf.extend(indent(self.anotations))
        if self.params:
            buf.append("\n    %s" % self.params)
        buf.append("\n>")
        return "".join(buf)


class Constructor(Node):
    def __init__(self, name, access, parent=None, params=None, throws=None, anotations=None):
        super().__init__()
        self.name = name
        self.access = access
        self.parent = parent
        self.params = params
        self.throws = throws
        self.anotations = anotations

    def __repr__(self):
        buf = ["<Constructor %s" % self.name]
        if self.access:
            buf.append(", %s" % self.access)
        if self.throws:
            buf.append(", throws %s" % " ".join(self.throws))
        if self.anotations:
            buf.extend(indent(self.anotations))
        if self.params:
            buf.append("\n    %s" % self.params)
        buf.append("\n>")
        return "".join(buf)


def tokenMap(func, *args):
    def pa(s,l,t):
        return [func(tokn, *args) for tokn in t]
    try:
        func_name = getattr(func, '__name__', getattr(func, '__class__').__name__)
    except Exception:
        func_name = str(func)
    pa.__name__ = func_name
    return pa


def indent(x):
    return ["\n    " + line for line in repr(x).splitlines()]


def parse_params(toks):
    for i, tokens in enumerate(toks):
        params = {}
        for key, name in tokens:
            params[key] = name
        toks[i] = params
    return toks


def parse_anotation(toks):
    for i, tok in enumerate(toks):
        toks[i] = [tok.name, tok.params[0]]
    return toks


def parse_anotations(toks):
    anotations = OrderedDict()
    for name, params in toks:
        anotations[name] = params
    return anotations

def parse_class(toks):
    methods = []
    constructors = []
    if toks.body:
        for item in toks.body:
            if isinstance(item, Method):
                methods.append(item)
            elif isinstance(item, Constructor):
                constructors.append(item)
    return Class(
        name=toks.name,
        parent= toks.parent[0],
        anotations=toks.anotations,
        access=toks.access,
        abstract=bool(toks.abstract),
        methods = methods,
        constructors = constructors)


def parse_constructor(toks):
    return Constructor(
        name = toks.name,
        access = toks.access,
        anotations = toks.anotations,
        throws = list(toks.throws) if toks.throws else [])


def parse_method(toks):
    return Method(
        name = toks.name,
        access = toks.access,
        override = bool(toks.override),
        abstract = bool(toks.abstract),
        is_async = bool(toks.is_async),
        rtype = toks.rtype,
        anotations = toks.anotations,
        throws = list(toks.throws) if toks.throws else [])


def parse_namespace(toks):
    return Namespace(toks.name, toks.members)


# VAPI Parser Grammar
ident = pp.Word(pp.alphas + '_', pp.alphanums + '_').setName("ident")
dot_ident = pp.Combine(ident + pp.ZeroOrMore(pp.Literal(".") + ident))
integer = pp.Regex(r'[+-]?\d+').setName("integer").setParseAction(tokenMap(int))
real = pp.Regex(r'[+-]?\d+\.\d*').setName("real").setParseAction(tokenMap(float))
sci_real = pp.Regex(r'[+-]?\d+([eE][+-]?\d+|\.\d*([eE][+-]?\d+)?)').setName("scireal").setParseAction(tokenMap(float))
number = (sci_real | real | integer).streamline()
string = pp.QuotedString("\"", "\\")
null = pp.Literal("null").setParseAction(lambda toks: None)
true = pp.Literal("true").setParseAction(lambda toks: True)
false = pp.Literal("false").setParseAction(lambda toks: False)
value = string | number | null | true | false
param = pp.Group(ident + pp.Literal("=").suppress() + value)
type_name = pp.Combine(dot_ident + pp.Optional(pp.Literal("?")))("type_name")
params = pp.Group(pp.Optional(param + pp.ZeroOrMore(pp.Literal(',').suppress() + param))).setParseAction(parse_params)("params")
params_in_parens = pp.Literal('(').suppress() + pp.Optional(params) + pp.Literal(')').suppress()
anotation = pp.Group(pp.Literal('[').suppress() + ident("name") + pp.Optional(params_in_parens) + pp.Literal(']').suppress()).setParseAction(parse_anotation)
anotations = pp.ZeroOrMore(anotation).setParseAction(parse_anotations)("anotations")
access = pp.Optional(pp.Keyword("protected") | pp.Keyword("public") | pp.Keyword("private") | pp.Keyword("internal"))("access")
abstract = pp.Optional(pp.Keyword("abstract"))("abstract")
is_async = pp.Optional(pp.Keyword("async"))("is_async")
override = pp.Optional(pp.Keyword("override"))("override")
throws = (pp.Optional(pp.Keyword("throws").suppress() + dot_ident + pp.ZeroOrMore(pp.Literal(',').suppress() + dot_ident)))("throws")
arg = type_name + ident + pp.Optional(pp.Literal("=") + value)
args = arg + pp.ZeroOrMore(pp.Literal(',') + arg)
args_in_parens = pp.Group(pp.Literal('(') + pp.Optional(args) + pp.Literal(')'))
method = (anotations + access + override + is_async + type_name()("rtype") + ident()("name") + args_in_parens + throws + pp.Literal(';').suppress()).setParseAction(parse_method)
member = pp.Group(access + type_name + ident + pp.Literal(';'));
constructor = (access + dot_ident()("name") + args_in_parens + throws + pp.Literal(';')).setParseAction(parse_constructor)
klass_body = pp.ZeroOrMore(constructor | method | member)
klass = (anotations + access + abstract + pp.Keyword("class") \
 + type_name()("name") + pp.Optional(pp.Literal(":").suppress() + type_name)("parent") \
 + pp.Group(pp.Literal('{').suppress() + klass_body + pp.Literal('}').suppress())("body")).setParseAction(parse_class)
namespace_elements = klass
namespace = (pp.Keyword("namespace").suppress() + dot_ident.copy()("name") + pp.Literal('{').suppress() + pp.Group(pp.ZeroOrMore(namespace_elements))("members") + pp.Literal('}').suppress()).setParseAction(parse_namespace)
toplevel = pp.OneOrMore(namespace | klass).ignore(pp.cppStyleComment)


def info(text):
    sys.stderr.write("Info: %s\n" % text)


class TestParser:
    def __init__(self):
        self.toplevel_ns = Namespace(None, None)
        self.classes = OrderedDict()
        self.namespaces = []
        self.class_names = set()
        self.children = []

    def parse(self, data):
        result = toplevel.parseString(data, parseAll=True)
        self.toplevel_ns = Namespace(None, result)
        self.ns = None
        self.walk_namespace(self.toplevel_ns)
        self.resolve_parents()
        return self.toplevel_ns

    def walk_namespace(self, ns):
        self.namespaces.append(self.ns)
        if self.ns and ns.name:
            self.ns += "." + ns.name
        else:
            self.ns = ns.name
        for item in ns.members:
            if isinstance(item, Namespace):
                self.walk_namespace(item)
            elif isinstance(item, Class):
                if self.ns:
                    item.name = self.ns + "." + item.name
                self.class_names.add(item.name)
                self.classes[item.name] = item
                if item.parent:
                    self.children.append((self.ns, item))
        self.ns = self.namespaces.pop()

    def resolve_parents(self):
        for ns, child in self.children:
            ns = ns.split(".") if ns else []
            while True:
                name = ".".join(ns + [child.parent])
                if name in self.class_names:
                    child.parent = name
                    break
                try:
                    ns.pop()
                except IndexError:
                    break

    def is_subclass(self, subclass, parent):
        while subclass:
            if subclass.parent == parent:
                return True
            subclass = self.classes.get(subclass.parent)
        return False

    def find_tests(self):
        for klass in self.classes.values():
            if not klass.name.endswith("Test"):
                info("The class %s has been ignored because it lacks the 'Test' suffix." % klass.name)
            elif klass.abstract:
                info("The class %s has been ignored because it is abstract." % klass.name)
            elif klass.access != "public":
                info("The class %s has been ignored because it is not public." % klass.name)
            elif not self.is_subclass(klass, "Drt.TestCase"):
                info("The class %s has been ignored because it is not a Drt.TestCase subclass." % klass.name)
            else:
                methods_found = set()
                base_path = "/" + klass.name.replace(".", "/") + "/"
                for method in self.find_test_methods(klass, methods_found):
                    path = base_path + method.name
                    yield (path, klass.name, method.name, method.is_async, method.throws)

    def find_test_methods(self, klass, methods_found):
        for method in klass.methods:
            name = method.name
            if name in methods_found:
                pass
            elif not name.startswith("test_"):
                if name not in ("set_up", "tear_down"):
                    info("The method %s has been ignored because it lacks the 'test_' prefix." % name)
            elif method.abstract:
                info("The method %s has been ignored because it is abstract." % name)
            elif method.access != "public":
                info("The method %s has been ignored because it is not public." % name)
            elif method.rtype != "void":
                info("The method %s has been ignored because it returns a value." % name)
            else:
                methods_found.add(method.name)
                yield method
        try:
            parent = self.classes[klass.parent]
        except KeyError:
            pass
        else:
            yield from self.find_test_methods(parent, methods_found)


class TestGenerator:
    def __init__(self, parser, prefix="diorite_testgen_"):
        self.parser = parser
        if prefix and prefix[-1] != "_":
            prefix += "_"
        self.prefix = prefix or ""

    def generate_tests(self, data):
        buf = ['/* Generated by Diorite Testgen */\n/* Included code blocks are in public domain */\n\n']
        self.parser.parse(data)
        run_funcs = []
        for path, klass, method, is_async, throws in self.parser.find_tests():
            run_func = self.prefix + "run" + path.replace("/", "_")
            run_funcs.append((path, run_func))
            buf.append('void %s()\n{\n' % run_func)
            buf.append('\tvar test = new %s();\n' % klass)
            buf.append('\ttest.set_up();\n')
            if is_async:
                buf.append('\tvar loop = new MainLoop();\n')
                buf.append('\ttest.%s.begin((o, res) =>\n' % method)
                buf.append('\t{\n')
                if throws:
                    buf.append('\t\ttry\n\t{\n\t\ttest.%s.end(res);\n\t\t}\n' % method)
                    for i, error in enumerate(throws):
                        buf.append('\t\tcatch (%s e%d)\n\t\t{\n\t\t\ttest.exception(e%d);\n\t\t}\n' % (error, i, i))
                else:
                    buf.append('\t\ttest.%s.end(res);\n' % method)
                buf.append('\t});\n')
            else:
                if throws:
                    buf.append('\ttry\n\t{\n\t\ttest.%s();\n\t}\n' % method)
                    for i, error in enumerate(throws):
                        buf.append('\tcatch (%s e%d)\n\t{\n\t\ttest.exception(e%d);\n\t}\n' % (error, i, i))
                else:
                    buf.append('\ttest.%s();\n' % method)
            buf.append('\ttest.tear_down();\n\ttest.summary();\n')
            buf.append('}\n\n')
        buf.append('int main(string[] argv)\n{\n')
        buf.append('\tGLib.Test.init(ref argv);\n')
        buf.append('\tTest.set_nonfatal_assertions();\n')
        for path, run_func in run_funcs:
            buf.append('\tGLib.Test.add_func("%s", %s);\n' % (path, run_func))
        buf.append('\treturn Test.run();\n}\n')
        return "".join(buf)


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("-i", "--input", type=argparse.FileType('r'), help="source files to extract test cases from")
    parser.add_argument("-o", "--output", type=argparse.FileType('w'), help="where to write generated test runner")
    args = parser.parse_args()

    input = args.input or sys.stdin
    output = args.output or sys.stdout
    generator = TestGenerator(TestParser())
    data = input.read()
    try:
        result = generator.generate_tests(data)
        output.write(result)
        sys.exit(0)
    except pp.ParseException as e:
        sys.stderr.write("Parse Error: %s\n" % e)
        sys.exit(1)
