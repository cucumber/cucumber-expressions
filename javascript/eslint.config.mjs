import importPlugin from "eslint-plugin-import";
import simpleImportSort from "eslint-plugin-simple-import-sort";
import n from "eslint-plugin-n";
import typescriptEslint from "@typescript-eslint/eslint-plugin";
import globals from "globals";
import tsParser from "@typescript-eslint/parser";
import js from "@eslint/js";

export default [js.configs.recommended, ...typescriptEslint.configs["flat/recommended"], {
    plugins: {
        import: importPlugin,
        "simple-import-sort": simpleImportSort,
        n,
    },

    languageOptions: {
        globals: {
            ...globals.browser,
            ...globals.node,
        },

        parser: tsParser,
        ecmaVersion: 5,
        sourceType: "module",

        parserOptions: {
            project: "tsconfig.json",
        },
    },
}, importPlugin.flatConfigs.typescript, {
    plugins: {
        "simple-import-sort": simpleImportSort,
    },

    rules: {
        "import/no-cycle": "error",
        "n/no-extraneous-import": "error",
        "@typescript-eslint/ban-ts-comment": "off",
        "@typescript-eslint/explicit-module-boundary-types": "off",
        "@typescript-eslint/explicit-function-return-type": "off",
        "@typescript-eslint/no-use-before-define": "off",
        "@typescript-eslint/no-explicit-any": "error",
        "@typescript-eslint/no-non-null-assertion": "error",
        "simple-import-sort/imports": "error",
        "simple-import-sort/exports": "error",
    },
}, {
    files: ["test/**"],

    rules: {
        "@typescript-eslint/no-non-null-assertion": "off",
    },
}];
