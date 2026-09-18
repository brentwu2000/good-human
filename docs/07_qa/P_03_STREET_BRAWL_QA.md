# P-03 Blind QA — Street Brawl

## Setup
Fresh context. Hide normal combat text/damage numbers. Do not explain intended camera behavior before exploratory test.

## Exploratory Questions
Did you feel like the dog during combat?
Could you understand the fight without text?
Did entering Dog POV increase tension?
Could you identify your owner and opponent throughout?
Did auto-framing ever fight your movement or cause discomfort?
Did Bark/Pull visibly affect events?
Could you predict meaningful attacks from motion?
Did the world react enough to make the conflict feel consequential?
Did victory/defeat have an emotional beat?

## Golden Path
Explore → encounter rival → tension → provoke → Dog POV → observe attacks → flank/Bark → Leash Pull → crisis → resolution → return to exploration.

## Fail Conditions
Text required to understand hits/outcome.
Humans stand still trading damage.
Dog loses meaningful movement.
Camera spins/jitters or causes discomfort.
POV frequently loses the central fight.
Bark/Pull feels like invisible stat modification.
Combat starts/ends abruptly without atmosphere.

## Gate
PASS only when combat is readable, tense, dog-centric and seamless with debug text disabled.
