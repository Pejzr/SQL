Z logu Ukázka_běhu_akce.trc je vidět, že největší zátěž a trvání má procedura hp_VratPorCisKHDoklad.

Zaměřil jsem se tedy na ni a zkusil ji optimalizovat za pomoci přednačtení opakovaného kódu do temp tabulek a doplnění individuálních podmínek.

CTE nešlo použít, protože ho nelze vložit do podmínky, ani za jiný select (Vždy musí být jako první).