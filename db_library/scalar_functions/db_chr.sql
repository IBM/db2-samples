--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Converts ASCII Latin-9 decimal code values to a UTF-8 value. A Netezza compatible version of CHR.
 */

CREATE OR REPLACE FUNCTION DB_CHR(I INTEGER)
    NO EXTERNAL ACTION
    DETERMINISTIC
RETURNS VARCHAR(4) 
RETURN    
    CASE
        WHEN I BETWEEN 1 AND 159 THEN CHR(I)
        WHEN I = 0 THEN U&'\0000'
        ELSE CASE I 
		WHEN 160 THEN U&'\00A0'  --  NBSP
		WHEN 161 THEN U&'\00A1'  --  ¡
		WHEN 162 THEN U&'\00A2'  --  ¢
		WHEN 163 THEN U&'\00A3'  --  £
		WHEN 164 THEN U&'\20AC'  --  €
		WHEN 165 THEN U&'\00A5'  --  ¥
		WHEN 166 THEN U&'\0160'  --  Š
		WHEN 167 THEN U&'\00A7'  --  §
		WHEN 168 THEN U&'\0161'  --  š
		WHEN 169 THEN U&'\00A9'  --  ©
		WHEN 170 THEN U&'\00AA'  --  ª
		WHEN 171 THEN U&'\00AB'  --  «
		WHEN 172 THEN U&'\00AC'  --  ¬
		WHEN 173 THEN U&'\00AD'  --  SHY
		WHEN 174 THEN U&'\00AE'  --  ®
		WHEN 175 THEN U&'\00AF'  --  ¯
		--
		WHEN 176 THEN U&'\00B0'  --  °
		WHEN 177 THEN U&'\00B1'  --  ±
		WHEN 178 THEN U&'\00B2'  --  ²
		WHEN 179 THEN U&'\00B3'  --  ³
		WHEN 180 THEN U&'\017D'  --  Ž
		WHEN 181 THEN U&'\00B5'  --  µ
		WHEN 182 THEN U&'\00B6'  --  ¶
		WHEN 183 THEN U&'\00B7'  --  ·
		WHEN 184 THEN U&'\017E'  --  ž
		WHEN 185 THEN U&'\00B9'  --  ¹
		WHEN 186 THEN U&'\00BA'  --  º
		WHEN 187 THEN U&'\00BB'  --  »
		WHEN 188 THEN U&'\0152'  --  Œ
		WHEN 189 THEN U&'\0153'  --  œ
		WHEN 190 THEN U&'\0178'  --  Ÿ
		WHEN 191 THEN U&'\00BF'  --  ¿
		--
		WHEN 192 THEN U&'\00C0'  --  À
		WHEN 193 THEN U&'\00C1'  --  Á
		WHEN 194 THEN U&'\00C2'  --  Â
		WHEN 195 THEN U&'\00C3'  --  Ã
		WHEN 196 THEN U&'\00C4'  --  Ä
		WHEN 197 THEN U&'\00C5'  --  Å
		WHEN 198 THEN U&'\00C6'  --  Æ
		WHEN 199 THEN U&'\00C7'  --  Ç
		WHEN 200 THEN U&'\00C8'  --  È
		WHEN 201 THEN U&'\00C9'  --  É
		WHEN 202 THEN U&'\00CA'  --  Ê
		WHEN 203 THEN U&'\00CB'  --  Ë
		WHEN 204 THEN U&'\00CC'  --  Ì
		WHEN 205 THEN U&'\00CD'  --  Í
		WHEN 206 THEN U&'\00CE'  --  Î
		WHEN 207 THEN U&'\00CF'  --  Ï
		--
		WHEN 208 THEN U&'\00D0'  --  Ð
		WHEN 209 THEN U&'\00D1'  --  Ñ
		WHEN 210 THEN U&'\00D2'  --  Ò
		WHEN 211 THEN U&'\00D3'  --  Ó
		WHEN 212 THEN U&'\00D4'  --  Ô
		WHEN 213 THEN U&'\00D5'  --  Õ
		WHEN 214 THEN U&'\00D6'  --  Ö
		WHEN 215 THEN U&'\00D7'  --  ×
		WHEN 216 THEN U&'\00D8'  --  Ø
		WHEN 217 THEN U&'\00D9'  --  Ù
		WHEN 218 THEN U&'\00DA'  --  Ú
		WHEN 219 THEN U&'\00DB'  --  Û
		WHEN 220 THEN U&'\00DC'  --  Ü
		WHEN 221 THEN U&'\00DD'  --  Ý
		WHEN 222 THEN U&'\00DE'  --  Þ
		WHEN 223 THEN U&'\00DF'  --  ß
		--
		WHEN 224 THEN U&'\00E0'  --  à
		WHEN 225 THEN U&'\00E1'  --  á
		WHEN 226 THEN U&'\00E2'  --  â
		WHEN 227 THEN U&'\00E3'  --  ã
		WHEN 228 THEN U&'\00E4'  --  ä
		WHEN 229 THEN U&'\00E5'  --  å
		WHEN 230 THEN U&'\00E6'  --  æ
		WHEN 231 THEN U&'\00E7'  --  ç
		WHEN 232 THEN U&'\00E8'  --  è
		WHEN 233 THEN U&'\00E9'  --  é
		WHEN 234 THEN U&'\00EA'  --  ê
		WHEN 235 THEN U&'\00EB'  --  ë
		WHEN 236 THEN U&'\00EC'  --  ì
		WHEN 237 THEN U&'\00ED'  --  í
		WHEN 238 THEN U&'\00EE'  --  î
		WHEN 239 THEN U&'\00EF'  --  ï
		--
		WHEN 240 THEN U&'\00F0'  --  ð
		WHEN 241 THEN U&'\00F1'  --  ñ
		WHEN 242 THEN U&'\00F2'  --  ò
		WHEN 243 THEN U&'\00F3'  --  ó
		WHEN 244 THEN U&'\00F4'  --  ô
		WHEN 245 THEN U&'\00F5'  --  õ
		WHEN 246 THEN U&'\00F6'  --  ö
		WHEN 247 THEN U&'\00F7'  --  ÷
		WHEN 248 THEN U&'\00F8'  --  ø
		WHEN 249 THEN U&'\00F9'  --  ù
		WHEN 250 THEN U&'\00FA'  --  ú
		WHEN 251 THEN U&'\00FB'  --  û
		WHEN 252 THEN U&'\00FC'  --  ü
		WHEN 253 THEN U&'\00FD'  --  ý
		WHEN 254 THEN U&'\00FE'  --  þ
		WHEN 255 THEN U&'\00FF'  --  ÿ
		END END