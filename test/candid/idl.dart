import 'package:agent_dart/agent_dart.dart';
import 'package:agent_dart/principal/principal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agent_dart/utils/extension.dart';
// ignore: library_prefixes
import 'package:agent_dart/candid/idl.dart';

void main() {
  idlTest();
}

testEncode(CType typ, dynamic val, String hex, String _str) {
  expect(IDL.encode([typ], [val]).toHex(include0x: false), hex);
}

testDecode(CType typ, dynamic val, String hex, String _str) {
  expect(IDL.decode([typ], hex.toU8a())[0], val);
}

// ignore: non_constant_identifier_names
test_(CType typ, dynamic val, String hex, String _str) {
  testEncode(typ, val, hex, _str);
  testDecode(typ, val, hex, _str);
}

// ignore: non_constant_identifier_names
test_args(List<CType> typs, List vals, String hex, String _str) {
  expect(IDL.encode(typs, vals), hex.toU8a());
  expect(IDL.decode(typs, hex.toU8a()), vals);
}

void idlTest() {
  test('IDL encoding (magic number)', () {
    // Wrong magic number
    expect(() => IDL.decode([IDL.Nat], '2a'.toU8a()),
        throwsA(contains('Message length smaller than magic number')));
    expect(() => IDL.decode([IDL.Nat], '4449444d2a'.toU8a()),
        throwsA(contains("Wrong magic number:")));
  });

  test('IDL encoding (empty)', () {
    // Empty
    expect(() => IDL.encode([IDL.Empty], [null]),
        throwsA(contains("Invalid empty argument:")));
    expect(
        () => IDL.decode([IDL.Empty], '4449444c00016f'.toU8a()),
        throwsA(contains(
          "Empty cannot appear as an output",
        )));
  });

  test('IDL encoding (null)', () {
    // Null
    test_(IDL.Null, null, '4449444c00017f', 'Null value');
  });

  test('IDL encoding (text)', () {
    // Text
    test_(IDL.Text, 'Hi ☃\n', '4449444c00017107486920e298830a',
        'Text with unicode');
    test_(
      IDL.Opt(IDL.Text),
      ['Hi ☃\n'],
      '4449444c016e7101000107486920e298830a',
      'Nested text with unicode',
    );
    expect(() => IDL.encode([IDL.Text], [0]),
        throwsA(contains("Invalid text argument")));
    expect(() => IDL.encode([IDL.Text], [null]),
        throwsA(contains("Invalid text argument")));
    expect(
        () => IDL.decode(
            [IDL.Vec(IDL.Nat8)], '4449444c00017107486920e298830a'.toU8a()),
        throwsA(contains(
            "type mismatch: type on the wire text, expect type vec nat8")));
  });

  test('IDL encoding (int)', () {
    // Int
    test_(IDL.Int, BigInt.from(0), '4449444c00017c00', 'Int');
    test_(IDL.Int, BigInt.from(42), '4449444c00017c2a', 'Int');
    test_(IDL.Int, BigInt.from(1234567890), '4449444c00017cd285d8cc04',
        'Positive Int');
    test_(
      IDL.Int,
      BigInt.parse('60000000000000000'),
      '4449444c00017c808098f4e9b5caea00',
      'Positive BigInt',
    );
    test_(IDL.Int, BigInt.from(-1234567890), '4449444c00017caefaa7b37b',
        'Negative Int');
    test_(IDL.Opt(IDL.Int), [BigInt.from(42)], '4449444c016e7c0100012a',
        'Nested Int');
    testEncode(IDL.Opt(IDL.Int), [42], '4449444c016e7c0100012a',
        'Nested Int (number)');
    expect(
        () => IDL.decode([IDL.Int], '4449444c00017d2a'.toU8a()),
        throwsA(contains(
          "type mismatch: type on the wire nat, expect type int",
        )));
  });

  test('IDL encoding (nat)', () {
    // Nat
    test_(IDL.Nat, BigInt.from(42), '4449444c00017d2a', 'Nat');
    test_(IDL.Nat, BigInt.from(0), '4449444c00017d00', 'Nat of 0');
    test_(IDL.Nat, BigInt.from(1234567890), '4449444c00017dd285d8cc04',
        'Positive Nat');
    test_(IDL.Nat, BigInt.parse('60000000000000000'),
        '4449444c00017d808098f4e9b5ca6a', 'Positive BigInt');
    testEncode(IDL.Opt(IDL.Nat), [BigInt.from(42)], '4449444c016e7d0100012a',
        'Nested Nat (number)');
    expect(() => IDL.encode([IDL.Nat], [-1]),
        throwsA(contains("Invalid nat argument")));
  });

  test('IDL encoding (float64)', () {
    // Float64
    test_(IDL.Float64, 3, '4449444c0001720000000000000840', 'Float');
    test_(IDL.Float64, 6, '4449444c0001720000000000001840', 'Float');
    test_(IDL.Float64, 0.5, '4449444c000172000000000000e03f', 'Float');
    // test_(IDL.Float64, Number.NaN, '4449444c000172010000000000f07f', 'NaN');
    test_(IDL.Float64, double.infinity, '4449444c000172000000000000f07f',
        '+infinity');
    test_(IDL.Float64, double.negativeInfinity,
        '4449444c000172000000000000f0ff', '-infinity');
    // test_(IDL.Float64, 4.94065645841247E-324, '4449444c000172000000000000b03c', 'eps');
    test_(IDL.Float64, double.minPositive, '4449444c0001720100000000000000',
        'min_value');
    test_(IDL.Float64, double.maxFinite, '4449444c000172ffffffffffffef7f',
        'max_value');
    // test_(IDL.Float64, (-(2 ^ 53 - 1)).toDouble(), '4449444c000172ffffffffffff3fc3',
    //     'min_safe_integer');
    // test_(
    //     IDL.Float64, (2 ^ 53 - 1).toDouble(), '4449444c000172ffffffffffff3f43', 'max_safe_integer');
  });

  test('IDL encoding (fixed-width number)', () {
    // Fixed-width number
    test_(IDL.Int8, 0, '4449444c00017700', 'Int8');
    test_(IDL.Int8, -1, '4449444c000177ff', 'Int8');
    test_(IDL.Int8, 42, '4449444c0001772a', 'Int8');
    test_(IDL.Int8, 127, '4449444c0001777f', 'Int8');
    test_(IDL.Int8, -128, '4449444c00017780', 'Int8');
    test_(IDL.Int32, 42, '4449444c0001752a000000', 'Int32');
    test_(IDL.Int32, -42, '4449444c000175d6ffffff', 'Negative Int32');
    test_(IDL.Int32, 1234567890, '4449444c000175d2029649', 'Positive Int32');
    test_(IDL.Int32, -1234567890, '4449444c0001752efd69b6', 'Negative Int32');
    test_(IDL.Int32, -0x7fffffff, '4449444c00017501000080', 'Negative Int32');
    test_(IDL.Int32, 0x7fffffff, '4449444c000175ffffff7f', 'Positive Int32');
    test_(
        IDL.Int64, BigInt.from(42), '4449444c0001742a00000000000000', 'Int64');
    test_(
        IDL.Int64, BigInt.from(-42), '4449444c000174d6ffffffffffffff', 'Int64');
    test_(IDL.Int64, BigInt.from(1234567890), '4449444c000174d202964900000000',
        'Positive Int64');
    test_(IDL.Nat8, 42, '4449444c00017b2a', 'Nat8');
    test_(IDL.Nat8, 0, '4449444c00017b00', 'Nat8');
    test_(IDL.Nat8, 255, '4449444c00017bff', 'Nat8');
    test_(IDL.Nat32, 0, '4449444c00017900000000', 'Nat32');
    test_(IDL.Nat32, 42, '4449444c0001792a000000', 'Nat32');
    test_(IDL.Nat32, 0xffffffff, '4449444c000179ffffffff', 'Nat32');
    test_(IDL.Nat64, BigInt.from(1234567890), '4449444c000178d202964900000000',
        'Positive Nat64');
    expect(() => IDL.encode([IDL.Nat32], [-42]),
        throwsA(contains("Invalid nat32 argument")));
    expect(() => IDL.encode([IDL.Int8], [256]),
        throwsA(contains("Invalid int8 argument")));
    expect(() => IDL.encode([IDL.Int32], [0xffffffff]),
        throwsA(contains("Invalid int32 argument")));
  });

  test('IDL encoding (tuple)', () {
    // Tuple
    test_(
      IDL.Tuple([IDL.Int, IDL.Text]),
      [BigInt.from(42), '💩'],
      '4449444c016c02007c017101002a04f09f92a9',
      'Pairs',
    );
    expect(
      () => IDL.encode([
        IDL.Tuple([IDL.Int, IDL.Text])
      ], [
        [0]
      ]),
      throwsA(contains("Invalid record {int; text} argument")),
    );
  });

  test('IDL encoding (array)', () {
    // Array
    test_(
      IDL.Vec(IDL.Int),
      [0, 1, 2, 3].map((x) => BigInt.from(x)).toList(),
      '4449444c016d7c01000400010203',
      'Array of Ints',
    );
    expect(() => IDL.encode([IDL.Vec(IDL.Int)], [BigInt.from(0)]),
        throwsA(contains("Invalid vec int argument")));
    expect(
        () => IDL.encode([
              IDL.Vec(IDL.Int)
            ], [
              ['fail']
            ]),
        throwsA(contains("Invalid vec int argument")));
  });

  test('IDL encoding (array + tuples)', () {
    // Array of Tuple
    test_(
      IDL.Vec(IDL.Tuple([IDL.Int, IDL.Text])),
      [
        [BigInt.from(42), 'text']
      ],
      '4449444c026c02007c01716d000101012a0474657874',
      'Arr of Tuple',
    );

    // Nested Tuples
    test_(
      IDL.Tuple([
        IDL.Tuple([
          IDL.Tuple([
            IDL.Tuple([IDL.Null])
          ])
        ])
      ]),
      [
        [
          [
            [null]
          ]
        ]
      ],
      '4449444c046c01007f6c0100006c0100016c0100020103',
      'Nested Tuples',
    );
  });

  test('IDL encoding (record)', () {
    // Record
    test_(IDL.Record({}), {}, '4449444c016c000100', 'Empty record');
    expect(
        () => IDL.encode([
              IDL.Record({"a": IDL.Text})
            ], [
              {"b": 'b'}
            ]),
        throwsA(contains("Record is missing key")));

    // Test that additional keys are ignored
    testEncode(
      IDL.Record({
        "foo": IDL.Text,
        "bar": IDL.Int,
      }),
      {"foo": '💩', "bar": BigInt.from(42), "baz": BigInt.from(0)},
      '4449444c016c02d3e3aa027c868eb7027101002a04f09f92a9',
      'Record',
    );
    testEncode(
      IDL.Record({"foo": IDL.Text, "bar": IDL.Int}),
      {"foo": '💩', "bar": BigInt.from(42)},
      '4449444c016c02d3e3aa027c868eb7027101002a04f09f92a9',
      'Record',
    );
  });

  test('IDL decoding (skip fields)', () {
    testDecode(
      IDL.Record({"foo": IDL.Text, "bar": IDL.Int}),
      {"foo": '💩', "bar": BigInt.from(42)},
      '4449444c016c04017f027ed3e3aa027c868eb702710100012a04f09f92a9',
      'ignore record fields',
    );
    testDecode(
      IDL.Variant({"ok": IDL.Text, "err": IDL.Text}),
      {"ok": 'good'},
      '4449444c016b03017e9cc20171e58eb4027101000104676f6f64',
      'adjust variant index',
    );
    final recordType = IDL.Record({"foo": IDL.Int32, "bar": IDL.Bool});
    final recordValue = {"foo": 42, "bar": true};
    test_(
      IDL.Record({
        "foo": IDL.Int32,
        "bar": recordType,
        "baz": recordType,
        "bib": recordType
      }),
      {"foo": 42, "bar": recordValue, "baz": recordValue, "bib": recordValue},
      '4449444c026c02d3e3aa027e868eb702756c04d3e3aa0200dbe3aa0200bbf1aa0200868eb702750101012a000000012a000000012a0000002a000000',
      'nested record',
    );
    testDecode(
      IDL.Record({
        "baz": IDL.Record({"foo": IDL.Int32})
      }),
      {
        "baz": {"foo": 42}
      },
      '4449444c026c02d3e3aa027e868eb702756c04d3e3aa0200dbe3aa0200bbf1aa0200868eb702750101012a000000012a000000012a0000002a000000',
      'skip nested fields',
    );
  });

  test('IDL encoding (numbered record)', () {
    // Record
    test_(
      IDL.Record({"_0_": IDL.Int8, "_1_": IDL.Bool}),
      {"_0_": 42, "_1_": true},
      '4449444c016c020077017e01002a01',
      'Numbered record',
    );
    // Test Tuple and numbered record are exact the same
    test_(IDL.Tuple([IDL.Int8, IDL.Bool]), [42, true],
        '4449444c016c020077017e01002a01', 'Tuple');
    test_(
      IDL.Tuple([
        IDL.Tuple([IDL.Int8, IDL.Bool]),
        IDL.Record({"_0_": IDL.Int8, "_1_": IDL.Bool})
      ]),
      [
        [42, true],
        {"_0_": 42, "_1_": true}
      ],
      '4449444c026c020077017e6c020000010001012a012a01',
      'Tuple and Record',
    );
    test_(
      IDL.Record({"_2_": IDL.Int8, "2": IDL.Bool}),
      {"_2_": 42, "2": true},
      '4449444c016c020277327e01002a01',
      'Mixed record',
    );
  });

  test('IDL encoding (bool)', () {
    // Bool
    test_(IDL.Bool, true, '4449444c00017e01', 'true');
    test_(IDL.Bool, false, '4449444c00017e00', 'false');
    expect(() => IDL.encode([IDL.Bool], [0]),
        throwsA(contains("Invalid bool argument")));
    expect(() => IDL.encode([IDL.Bool], ['false']),
        throwsA(contains("Invalid bool argument")));
  });

  test('IDL encoding (principal)', () {
    // Principal
    test_(
      IDL.Principal,
      Principal.fromText('w7x7r-cok77-xa'),
      '4449444c0001680103caffee',
      'principal',
    );
    test_(
      IDL.Principal,
      Principal.fromText('2chl6-4hpzw-vqaaa-aaaaa-c'),
      '4449444c0001680109efcdab000000000001',
      'principal',
    );
    expect(
        () => IDL.encode([IDL.Principal], ['w7x7r-cok77-xa']),
        throwsA(contains(
          "Invalid principal argument",
        )));
    expect(
        () => IDL.decode([IDL.Principal], '4449444c00016803caffee'.toU8a()),
        throwsA(contains(
          "Cannot decode principal",
        )));
  });

  test('IDL encoding (function)', () {
    // Function
    test_(
      IDL.Func([IDL.Text], [IDL.Nat], []),
      [Principal.fromText('w7x7r-cok77-xa'), 'foo'],
      '4449444c016a0171017d000100010103caffee03666f6f',
      'function',
    );
    test_(
      IDL.Func([IDL.Text], [IDL.Nat], ['query']),
      [Principal.fromText('w7x7r-cok77-xa'), 'foo'],
      '4449444c016a0171017d01010100010103caffee03666f6f',
      'query function',
    );
  });

  test('IDL encoding (service)', () {
    // Service
    test_(
      IDL.Service({
        "foo": IDL.Func([IDL.Text], [IDL.Nat], [])
      }),
      Principal.fromText('w7x7r-cok77-xa'),
      '4449444c026a0171017d00690103666f6f0001010103caffee',
      'service',
    );
    test_(
      IDL.Service({
        "foo": IDL.Func([IDL.Text], [IDL.Nat], ['query'])
      }),
      Principal.fromText('w7x7r-cok77-xa'),
      '4449444c026a0171017d0101690103666f6f0001010103caffee',
      'service',
    );
    test_(
      IDL.Service({
        "foo": IDL.Func([IDL.Text], [IDL.Nat], []),
        "foo2": IDL.Func([IDL.Text], [IDL.Nat], []),
      }),
      Principal.fromText('w7x7r-cok77-xa'),
      '4449444c026a0171017d00690203666f6f0004666f6f320001010103caffee',
      'service',
    );
  });

  test('IDL encoding (variants)', () {
    // Variants
    // ignore: non_constant_identifier_names
    final Result = IDL.Variant({"ok": IDL.Text, "err": IDL.Text});
    test_(Result, {"ok": 'good'},
        '4449444c016b029cc20171e58eb4027101000004676f6f64', 'Result ok');
    test_(Result, {"err": 'uhoh'},
        '4449444c016b029cc20171e58eb402710100010475686f68', 'Result err');
    expect(() => IDL.encode([Result], [{}]),
        throwsA(contains("Invalid variant {ok:text; err:text} argument")));
    expect(
        () => IDL.encode([
              Result
            ], [
              {"ok": 'ok', "err": 'err'}
            ]),
        throwsA(contains("Invalid variant {ok:text; err:text} argument")));

    // Test that nullary constructors work as expected
    test_(
      IDL.Variant({"foo": IDL.Null}),
      {"foo": null},
      '4449444c016b01868eb7027f010000',
      'Nullary constructor in variant',
    );

    // Test that Empty within variants works as expected
    test_(
      IDL.Variant({"ok": IDL.Text, "err": IDL.Empty}),
      {"ok": 'good'},
      '4449444c016b029cc20171e58eb4026f01000004676f6f64',
      'Empty within variants',
    );
    expect(
        () => IDL.encode([
              IDL.Variant({"ok": IDL.Text, "err": IDL.Empty})
            ], [
              {"err": 'uhoh'}
            ]),
        throwsA(contains("Invalid variant {ok:text; err:empty} argument:")));

    // Test for option
    test_(IDL.Opt(IDL.Nat), [], '4449444c016e7d010000', 'None option');
    test_(IDL.Opt(IDL.Nat), [BigInt.from(1)], '4449444c016e7d01000101',
        'Some option');
    test_(
        IDL.Opt(IDL.Opt(IDL.Nat)),
        [
          [BigInt.from(1)]
        ],
        '4449444c026e7d6e000101010101',
        'Nested option');
    test_(
        IDL.Opt(IDL.Opt(IDL.Null)),
        [
          [null]
        ],
        '4449444c026e7f6e0001010101',
        'Null option');

    // Type description sharing
    test_(
      IDL.Tuple([
        IDL.Vec(IDL.Int),
        IDL.Vec(IDL.Nat),
        IDL.Vec(IDL.Int),
        IDL.Vec(IDL.Nat)
      ]),
      [[], [], [], []],
      '4449444c036d7c6d7d6c040000010102000301010200000000',
      'Type sharing',
    );
  });

  test('IDL encoding (rec)', () {
    // Test for recursive types
    // ignore: non_constant_identifier_names
    final List = IDL.Rec();
    expect(() => IDL.encode([List], [[]]),
        throwsA(contains("Recursive type uninitialized")));
    List.fill(IDL.Opt(IDL.Record({"head": IDL.Int, "tail": List})));
    test_(List, [], '4449444c026e016c02a0d2aca8047c90eddae70400010000',
        'Empty list');
    test_(
      List,
      [
        {
          "head": BigInt.from(1),
          "tail": [
            {"head": BigInt.from(2), "tail": []}
          ]
        }
      ],
      '4449444c026e016c02a0d2aca8047c90eddae7040001000101010200',
      'List',
    );

    // Mutual recursion
    // ignore: non_constant_identifier_names
    final List1 = IDL.Rec();
    // ignore: non_constant_identifier_names
    final List2 = IDL.Rec();
    List1.fill(IDL.Opt(List2));
    List2.fill(IDL.Record({"head": IDL.Int, "tail": List1}));
    test_(List1, [], '4449444c026e016c02a0d2aca8047c90eddae70400010000',
        'Empty list');
    test_(
      List1,
      [
        {
          "head": BigInt.from(1),
          "tail": [
            {"head": BigInt.from(2), "tail": []}
          ]
        }
      ],
      '4449444c026e016c02a0d2aca8047c90eddae7040001000101010200',
      'List',
    );
  });

  test('IDL encoding (multiple arguments)', () {
    // ignore: non_constant_identifier_names
    final Result = IDL.Variant({"ok": IDL.Text, "err": IDL.Text});

    // Test for multiple arguments
    test_args(
      [IDL.Nat, IDL.Opt(IDL.Text), Result],
      [
        BigInt.from(42),
        ['test'],
        {"ok": 'good'}
      ],
      '4449444c026e716b029cc20171e58eb40271037d00012a0104746573740004676f6f64',
      'Multiple arguments',
    );
    test_args([], [], '4449444c0000', 'empty args');
  });
}
