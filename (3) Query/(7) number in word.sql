    FUNCTION AMOUNT_IN_WORD (P_AMT IN NUMBER)
        RETURN VARCHAR2
    IS
        M_MAIN_AMT_TEXT     VARCHAR2 (2000);
        M_TOP_AMT_TEXT      VARCHAR2 (2000);
        M_BOTTOM_AMT_TEXT   VARCHAR2 (2000);
        M_DECIMAL_TEXT      VARCHAR2 (2000);
        M_TOP               NUMBER (20, 5);
        M_MAIN_AMT          NUMBER (20, 5);
        M_TOP_AMT           NUMBER (20, 5);
        M_BOTTOM_AMT        NUMBER (20, 5);
        M_DECIMAL           NUMBER (20, 5);
        M_AMT               NUMBER (20, 5);
        M_TEXT              VARCHAR2 (2000);
    BEGIN
        M_MAIN_AMT := NULL;
        M_TOP_AMT_TEXT := NULL;
        M_BOTTOM_AMT_TEXT := NULL;
        M_DECIMAL_TEXT := NULL;
        M_DECIMAL := TRUNC (ABS (P_AMT), 2) - TRUNC (ABS (P_AMT));

        IF M_DECIMAL > 0
        THEN
            M_DECIMAL := M_DECIMAL * 100;
        END IF;

        M_AMT := TRUNC (ABS (P_AMT));
        M_TOP := TRUNC (M_AMT / 100000); 
        M_MAIN_AMT := TRUNC (M_TOP / 100); -- Core
        M_TOP_AMT := M_TOP - (M_MAIN_AMT * 100); --Lac
        M_BOTTOM_AMT := M_AMT - (M_TOP * 100000); --Thousand

        IF M_MAIN_AMT > 0
        THEN
            M_MAIN_AMT_TEXT := TO_CHAR (TO_DATE (M_MAIN_AMT, 'J'), 'JSP');

            IF M_MAIN_AMT = 1
            THEN
                M_MAIN_AMT_TEXT := M_MAIN_AMT_TEXT || ' CRORE ';
            ELSE
                M_MAIN_AMT_TEXT := M_MAIN_AMT_TEXT || ' CRORES ';
            END IF;
        END IF;

        IF M_TOP_AMT > 0
        THEN
            M_TOP_AMT_TEXT := TO_CHAR (TO_DATE (M_TOP_AMT, 'J'), 'JSP');

            IF M_TOP_AMT = 1
            THEN
                M_TOP_AMT_TEXT := M_TOP_AMT_TEXT || ' LAC ';
            ELSE
                M_TOP_AMT_TEXT := M_TOP_AMT_TEXT || ' LACS ';
            END IF;
        END IF;

        IF M_BOTTOM_AMT > 0
        THEN
            M_BOTTOM_AMT_TEXT := TO_CHAR (TO_DATE (M_BOTTOM_AMT, 'J'), 'JSP');
        END IF;

        IF M_DECIMAL > 0
        THEN
            IF NVL (M_BOTTOM_AMT, 0) + NVL (M_TOP_AMT, 0) > 0
            THEN
                M_DECIMAL_TEXT :=
                    'AND ' || INITCAP (TO_CHAR (TO_DATE (M_DECIMAL, 'J'), 'JSP')) || ' PAISA ';
            ELSE
                M_DECIMAL_TEXT :=
                    'AND ' || INITCAP (TO_CHAR (TO_DATE (M_DECIMAL, 'J'), 'JSP')) || ' PAISA ';
            END IF;
        END IF;

        M_TEXT :=
               INITCAP (M_MAIN_AMT_TEXT)
            || INITCAP (M_TOP_AMT_TEXT)
            || INITCAP (M_BOTTOM_AMT_TEXT)
            || ' TAKA '
            || M_DECIMAL_TEXT
            || 'ONLY';
        M_TEXT := UPPER (SUBSTR (M_TEXT, 1, 1)) || SUBSTR (M_TEXT, 2);
        M_TEXT := ' ' || M_TEXT;
        RETURN (TRIM (
                    CASE
                        WHEN SUBSTR (TRIM (REPLACE (M_TEXT, '-', ' ')), 1, 4) = 'TAKA'
                        THEN
                            SUBSTR (TRIM (REPLACE (M_TEXT, '-', ' ')), 10, 2000)
                        ELSE
                            TRIM (REPLACE (M_TEXT, '-', ' '))
                    END));
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN 'Input Is Too Long To Display';
    END AMOUNT_IN_WORD;