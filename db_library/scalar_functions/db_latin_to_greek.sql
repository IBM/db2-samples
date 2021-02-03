--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Replaces Latin characters with Greek equivalents
 */

CREATE OR REPLACE FUNCTION DB_LATIN_TO_GREEK(I VARCHAR(32000))
    NO EXTERNAL ACTION
    DETERMINISTIC
RETURNS VARCHAR(32000)
RETURN (
REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
 I
,'e','ε')
,'r','ρ')
,'t','τ')
,'y','υ')
,'u','θ')
,'i','ι')
,'o','ο')
,'p','π')
,'a','α')
,'s','σ')
,'d','δ')
,'f','φ')
,'g','γ')
,'h','η')
,'j','ξ')
,'k','κ')
,'l','λ')
,'z','ζ')
,'x','χ')
,'c','ψ')
,'v','ω')
,'b','β')
,'n','ν')
,'m','μ')
,'E','Ε')
,'R','Ρ')
,'T','Τ')
,'Y','Υ')
,'U','Θ')
,'I','Ι')
,'O','Ο')
,'P','Π')
,'A','Α')
,'S','Σ')
,'D','Δ')
,'F','Φ')
,'G','Γ')
,'H','Η')
,'J','Ξ')
,'K','Κ')
,'L','Λ')
,'Z','Ζ')
,'X','Χ')
,'C','Ψ')
,'V','Ω')
,'B','Β')
,'N','Ν')
,'M','Μ')
)