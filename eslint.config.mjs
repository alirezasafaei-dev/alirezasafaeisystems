import nextCoreWebVitals from "eslint-config-next/core-web-vitals";
import nextTypescript from "eslint-config-next/typescript";

const eslintConfig = [
  ...nextCoreWebVitals,
  ...nextTypescript,
  {
    rules: {
      // TypeScript - Warnings for gradual adoption
      "@typescript-eslint/no-explicit-any": "warn",
      "@typescript-eslint/no-unused-vars": ["warn", { "argsIgnorePattern": "^_" }],
      "@typescript-eslint/no-non-null-assertion": "warn",
      "@typescript-eslint/ban-ts-comment": "warn",
      "@typescript-eslint/prefer-as-const": "error",
      
      // React - Best practices
      "react/no-unescaped-entities": "off",
      
      // Next.js
      "@next/next/no-img-element": "warn",
      
      // General - Code quality
      "prefer-const": "error",
      "no-console": ["warn", { "allow": ["error", "warn"] }],
      "no-debugger": "error",
      "no-unused-vars": "off", // Handled by TypeScript
    },
  },
  {
    ignores: [
      "examples/**",
      "node_modules/**",
      ".next/**",
      "out/**",
      "build/**",
      "storybook-static/**",
      "playwright-report/**",
      "_ops/**",
      "coverage/**",
      "next-env.d.ts",
      "examples/**",
      "skills",
      "worktrees/**",
      "sites/**"
    ]
  }
];

export default eslintConfig;
