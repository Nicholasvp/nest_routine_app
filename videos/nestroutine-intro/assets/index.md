# Sourced assets — NestRoutine intro

Single asset need; no external search was required (all content is user-supplied or read from the app repo).

| Role  | Frozen path                       | Kind  | Provenance                                                                        | Treatment |
| ----- | --------------------------------- | ----- | --------------------------------------------------------------------------------- | --------- |
| hero  | `assets/nest_routine_logo.png`    | logo  | user-supplied app launcher icon, copied from `../../assets/nest_routine_logo.png`  | none      |

## Asset notes (measured, not assumed)

- 400x400 PNG, **fully opaque** — it carries its own baked purple gradient square
  (corner ~#331862 -> edge ~#62348F) with a light cream-lavender nest mark centered in it.
- No transparency: do **not** plan a transparency-dependent reveal or expect a cutout.
- Composite it whole as a rounded app-icon tile on the deepNavy ground; give it a
  softLavender/sleepGlow bloom halo so the square's dark purple edges melt into the
  background instead of reading as a hard square.
- No SVG/vector source exists in the repo => no draw-on / vectorize path.
- Optional alternative (not used): `npx hyperframes remove-background` would cut the light
  mark out of the purple square, but pastel edge ringing is likely.

See `../shot-plan.json` -> `asset_needs[0].note` for the same guidance.
