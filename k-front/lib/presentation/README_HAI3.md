# Presentation Layer – HAI3 Structure

This folder follows **HAI3**-inspired Atomic Design for Flutter (Atoms → Molecules → Organisms).

## Layout

| Layer      | Path           | Role |
|-----------|----------------|------|
| **Atoms** | `atoms/`       | Single-purpose primitives: buttons, inputs, labels. |
| **Molecules** | `molecules/` | Composed UI: search result row, message bubble, chat row. |
| **Organisms** | `organisms/` | Full blocks: search delegate, chat header. |
| **Screens** | `screens/`   | Full screens composing organisms/molecules. |
| **Widgets** | `widgets/`   | Re-exports and legacy widgets; prefer atoms/molecules/organisms for new code. |

## Current Mapping

- **Atoms:** `airy_button`, `airy_input_field`
- **Molecules:** `chat_search_result_tile`
- **Organisms:** `chat_search_delegate`
- **Widgets** (`widgets/`) re-export from these layers for backward compatibility.

## Reference

- HAI3: https://github.com/HAI3org/HAI3
- UI Core: Presentation (component library) → Layout → Libraries
