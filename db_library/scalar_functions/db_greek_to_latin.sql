--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Replaces Greek characters with Latin equivalents
 */

CREATE OR REPLACE FUNCTION DB_GREEK_TO_LATIN(I VARCHAR(32000))
    NO EXTERNAL ACTION
    DETERMINISTIC
RETURNS VARCHAR(32000)
RETURN (
REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
 I
,'ε','e')
,'ρ','r')
,'τ','t')
,'υ','y')
,'θ','u')
,'ι','i')
,'ο','o')
,'π','p')
,'α','a')
,'σ','s')
,'δ','d')
,'φ','f')
,'γ','g')
,'η','h')
,'ξ','j')
,'κ','k')
,'λ','l')
,'ζ','z')
,'χ','x')
,'ψ','c')
,'ω','v')
,'β','b')
,'ν','n')
,'μ','m')
,'Ε','E')
,'Ρ','R')
,'Τ','T')
,'Υ','Y')
,'Θ','U')
,'Ι','I')
,'Ο','O')
,'Π','P')
,'Α','A')
,'Σ','S')
,'Δ','D')
,'Φ','F')
,'Γ','G')
,'Η','H')
,'Ξ','J')
,'Κ','K')
,'Λ','L')
,'Ζ','Z')
,'Χ','X')
,'Ψ','C')
,'Ω','V')
,'Β','B')
,'Ν','N')
,'Μ','M')
)