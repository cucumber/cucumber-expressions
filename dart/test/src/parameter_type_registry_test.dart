import 'package:cucumber_expressions/src/errors.dart';
import 'package:cucumber_expressions/src/parameter_type.dart';
import 'package:cucumber_expressions/src/parameter_type_lookup.dart';
import 'package:cucumber_expressions/src/parameter_type_registry.dart';
import 'package:test/test.dart';

class Name {
  Name(this.name);
  final String name;
}

class Person {
  Person(this.name);
  final String name;
}

class Place {
  Place(this.name);
  final String name;
}

final RegExp capitalisedWord = RegExp(r'[A-Z]+\w+');

void main() {
  group('ParameterTypeRegistry', () {
    late ParameterTypeRegistry registry;

    setUp(() {
      registry = ParameterTypeRegistry();
    });

    test('does not allow more than one preferential parameter type per regexp',
        () {
      registry
        ..defineParameterType(
          ParameterType<Name>(
            'name',
            capitalisedWord,
            'Name',
            (s) => Name(s.first!),
            useForSnippets: true,
            preferForRegexpMatch: true,
          ),
        )
        ..defineParameterType(
          ParameterType<Person>(
            'person',
            capitalisedWord,
            'Person',
            (s) => Person(s.first!),
            useForSnippets: true,
            preferForRegexpMatch: false,
          ),
        );
      expect(
        () => registry.defineParameterType(
          ParameterType<Place>(
            'place',
            capitalisedWord,
            'Place',
            (s) => Place(s.first!),
            useForSnippets: true,
            preferForRegexpMatch: true,
          ),
        ),
        throwsA(
          isA<CucumberExpressionException>().having(
            (e) => e.message,
            'message',
            equals(
              'There can only be one preferential parameter type per regexp. '
              'The regexp /${capitalisedWord.pattern}/ is used for two '
              'preferential parameter types, {name} and {place}',
            ),
          ),
        ),
      );
    });

    test('looks up preferential parameter type by regexp', () {
      final name = ParameterType<Name>(
        'name',
        RegExp(r'[A-Z]+\w+'),
        'Name',
        (s) => Name(s.first!),
        useForSnippets: true,
        preferForRegexpMatch: false,
      );
      final person = ParameterType<Person>(
        'person',
        RegExp(r'[A-Z]+\w+'),
        'Person',
        (s) => Person(s.first!),
        useForSnippets: true,
        preferForRegexpMatch: true,
      );
      final place = ParameterType<Place>(
        'place',
        RegExp(r'[A-Z]+\w+'),
        'Place',
        (s) => Place(s.first!),
        useForSnippets: true,
        preferForRegexpMatch: false,
      );

      registry
        ..defineParameterType(name)
        ..defineParameterType(person)
        ..defineParameterType(place);

      expect(
        lookupParameterTypeByRegexp(
          registry,
          r'[A-Z]+\w+',
          RegExp(r'([A-Z]+\w+) and ([A-Z]+\w+)'),
          'Lisa and Bob',
        ),
        same(person),
      );
    });

    test('rejects duplicate names and preserves non-preferential types', () {
      registry.defineParameterType(
        ParameterType<Name>(
          'name',
          'name',
          'Name',
          (values) => Name(values.first!),
        ),
      );
      expect(
        () => registry.defineParameterType(
          ParameterType<Person>(
            'name',
            'person',
            'Person',
            (values) => Person(values.first!),
          ),
        ),
        throwsA(isA<CucumberExpressionException>()),
      );

      registry
        ..defineParameterType(
          ParameterType<Person>(
            'person',
            'identity',
            'Person',
            (values) => Person(values.first!),
          ),
        )
        ..defineParameterType(
          ParameterType<Place>(
            'place',
            'identity',
            'Place',
            (values) => Place(values.first!),
          ),
        );
      expect(
        registeredParameterTypesByRegexp(registry, 'identity')!
            .map((type) => type.name),
        ['person', 'place'],
      );
    });

    test('contains the complete built-in registry contract', () {
      expect(
        registeredParameterTypes(registry).map((type) => type.name),
        containsAll([
          'int',
          'float',
          'word',
          'string',
          '',
          'double',
          'bigdecimal',
          'byte',
          'short',
          'long',
          'biginteger',
        ]),
      );
      expect(
        registeredParameterTypeByName(registry, '')!.useForSnippets,
        isFalse,
      );
      expect(
        registeredParameterTypeByName(registry, 'int')!.preferForRegexpMatch,
        isTrue,
      );
    });
  });
}
