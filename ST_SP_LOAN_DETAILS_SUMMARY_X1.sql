CREATE OR REPLACE procedure APPS.ST_SP_LOAN_DETAILS_SUMMARY_X1(P_ORG_ID IN NUMBER,P_BANK_ID IN NUMBER, P_LOAN_ID IN NUMBER, P_FROM_DATE IN DATE, P_TO_DATE IN DATE)
 AS

 BEGIN



 BEGIN
--POPULATING DATA TO GT TABLE




INSERT INTO ST_LOAN_DETAILS_GT (ORG_ID,
                                BANK_ID,
                                LOAN_ID,
                                SL,
                                ACCOUNTING_DATE,
                                CHARGE_TYPE,
                                CR_AMOUNT,
                                DR_AMOUNT,
                                INTEREST_RATE,
                                VOUCHER)
   SELECT DISTINCT ORG_ID,
                   BANK_ID,
                   LOAN_ID,
                   SL,
                   ACCOUNTING_DATE,
                   CHARGE_TYPE,
                   CR_AMOUNT,
                   DR_AMOUNT,
                   INTEREST_RATE,
                   VOUCHER
     FROM xx_lt_loan_data1
    WHERE     ORG_ID = NVL(P_ORG_ID,ORG_ID)
          AND BANK_ID = P_BANK_ID
          AND LOAN_ID = NVL (P_LOAN_ID, LOAN_ID)
          --AND to_char(ACCOUNTING_DATE,'YYYY/MM/DD HH24:MI:SS') BETWEEN P_FROM_DATE AND P_TO_DATE;
          AND trim(ACCOUNTING_DATE) >= trunc(P_FROM_DATE) AND trunc(ACCOUNTING_DATE) <= trunc(P_TO_DATE);
		

END;

-----------
INSERT INTO ST_LOAN_DETAILS_X1_GT (ORG_ID,
                                   BANK_NAME,
                                   MAJOR_LOAN_TYPE,
                                   LOAN_TYPE_CODE,
                                   LOAN_ID,
                                   LOAN_NUMBER,
                                   OPENING_DATE,
                                   LC_NUMBER,
                                   EFFECTIVE_START_DATE,
                                   EFFECTIVE_END_DATE,
                                   CURRENCY_CODE,
                                   LOAN_AMOUNT,
                                   FOREIGN_CURRENCY_RATE,
                                   OB_PRINCIPLE,
                                   OB_INTEREST,
                                   OB_TOTAL,
                                   ADD_PRINCIPLE,
                                   ADD_INTEREST,
                                   ADD_TOTAL,
                                   ADJST_PRINCIPLE,
                                   ADJST_INTEREST,
                                   ADJST_TOTAL,
                                   NETT_PAY_PRINCIPLE,
                                   NETT_PAY_INTEREST,
                                   NETT_PAY_TOTAL,
                                   PAYMENT_DATE)

----------
SELECT ORG_ID,
       BANK_NAME,
       MAJOR_LOAN_TYPE,
       LOAN_TYPE_CODE,
       LOAN_ID,
       LOAN_NUMBER,
       OPENING_DATE,
       LC_NUMBER,
       EFFECTIVE_START_DATE,
       EFFECTIVE_END_DATE,
       CURRENCY_CODE,
       LOAN_AMOUNT,
       FOREIGN_CURRENCY_RATE,
       OB_PRINCIPLE,
       OB_INTEREST,
       OB_TOTAL,
       ADD_PRINCIPLE,
       ADD_INTEREST,
       ADD_TOTAL,
       ADJST_PRINCIPLE,
       ADJST_INTEREST,
       ADJST_TOTAL,
       FN_GET_NEGI_TO_ZERO (OB_PRINCIPLE + ADD_PRINCIPLE - ADJST_PRINCIPLE)
          NETT_PAY_PRINCIPLE,
       CASE
          WHEN TRUNC (
                  FN_GET_NEGI_TO_ZERO (
                     OB_PRINCIPLE + ADD_PRINCIPLE - ADJST_PRINCIPLE)) <= 0
          THEN
             0
          ELSE
             FN_GET_NEGI_TO_ZERO (
                OB_INTEREST + ADD_INTEREST - ADJST_INTEREST)
       END
          NETT_PAY_INTEREST,
       CASE
          WHEN TRUNC (
                  FN_GET_NEGI_TO_ZERO (
                     OB_PRINCIPLE + ADD_PRINCIPLE - ADJST_PRINCIPLE)) <= 0
          THEN
             0
          ELSE
             FN_GET_NEGI_TO_ZERO (
                  (OB_PRINCIPLE + ADD_PRINCIPLE - ADJST_PRINCIPLE)
                + (OB_INTEREST + ADD_INTEREST - ADJST_INTEREST))
       END
          NETT_PAY_TOTAL,
       PAYMENT_DATE
FROM
(
SELECT DISTINCT
       ORG_ID,
       BANK_NAME,
       MAJOR_LOAN_TYPE,
       LOAN_TYPE_CODE,
       LOAN_ID,
       LOAN_NUMBER,
       OPENING_DATE,
       LC_NUMBER,
       EFFECTIVE_START_DATE,
       EFFECTIVE_END_DATE,
       CURRENCY_CODE,
       LOAN_AMOUNT,
       FOREIGN_CURRENCY_RATE,
       OB_PRINCIPLE,
       OB_INTEREST,
       (OB_PRINCIPLE + OB_INTEREST) OB_TOTAL,
       ADD_PRINCIPLE,
       NVL (
          FN_GET_LOAN_INTER (NVL (ADD_PRINCIPLE, 0) + NVL (OB_PRINCIPLE, 0),
                             LOAN_ID,
                             P_FROM_DATE,
                             P_TO_DATE),
          0)
          ADD_INTEREST,
       (  ADD_PRINCIPLE
        + NVL (
             FN_GET_LOAN_INTER (
                NVL (ADD_PRINCIPLE, 0) + NVL (OB_PRINCIPLE, 0),
                LOAN_ID,
                P_FROM_DATE,
                P_TO_DATE),
             0))
          ADD_TOTAL,
       ADJST_PRINCIPLE,
       ADJST_INTEREST,
       (ADJST_PRINCIPLE + ADJST_INTEREST) ADJST_TOTAL,
       FN_GET_NEGI_TO_ZERO (OB_PRINCIPLE + ADD_PRINCIPLE - ADJST_PRINCIPLE)
          NETT_PAY_PRINCIPLE,
       FN_GET_NEGI_TO_ZERO (
          CASE
             WHEN SIGN (OB_INTEREST + ADD_INTEREST - ADJST_INTEREST) = -1
             THEN
                0
             ELSE
                (OB_INTEREST + ADD_INTEREST - ADJST_INTEREST)
          END)
          NETT_PAY_INTEREST,
       FN_GET_NEGI_TO_ZERO (
            (OB_PRINCIPLE + ADD_PRINCIPLE - ADJST_PRINCIPLE)
          + (CASE
                WHEN SIGN (OB_INTEREST + ADD_INTEREST - ADJST_INTEREST) = -1
                THEN
                   0
                ELSE
                   (OB_INTEREST + ADD_INTEREST - ADJST_INTEREST)
             END))
          NETT_PAY_TOTAL,
       PAYMENT_DATE
FROM
(
SELECT XX_LOAN_DET.ORG_ID,
       XX_LOAN_DET.BANK_NAME,
       XX_LOAN_DET.MAJOR_LOAN_TYPE,
       XX_LOAN_DET.LOAN_TYPE_CODE,
       XX_LOAN_DET.LOAN_ID,
       XX_LOAN_DET.LOAN_NUMBER,
       XX_LOAN_DET.OPENING_DATE,
       XX_LOAN_DET.LC_NUMBER,
       XX_LOAN_DET.LC_ID,
       XX_LOAN_DET.EFFECTIVE_START_DATE,
       XX_LOAN_DET.EFFECTIVE_END_DATE,
       XX_LOAN_DET.INTEREST_RATE,
       XX_LOAN_DET.CURRENCY_CODE,
       XX_LOAN_DET.LC_TYPE,
       XX_LOAN_DET.LOAN_AMOUNT,
       XX_LOAN_DET.FOREIGN_CURRENCY_RATE,
       XX_LOAN_DET.FOREIGN_CURRENCY_DATE,
       ST_LOAN_SUMM.NETT_PAY_PRINCIPLE OB_PRINCIPLE,
       ST_LOAN_SUMM.NETT_PAY_INTEREST OB_INTEREST,
       ST_LOAN_SUMM.NETT_PAY_TOTAL OB_TOTAL,
       (NVL (
           (SELECT SUM (NVL (ABS (CR_AMOUNT), 0))
              FROM ST_LOAN_DETAILS_GT
             WHERE     LOAN_ID = XX_LOAN_DET.LOAN_ID
                   AND UPPER (CHARGE_TYPE) = 'PRINCIPLE'),
           0))
          ADD_PRINCIPLE,
       NVL (FN_GET_LOAN_INTER (P_BANK_ID,
                               P_LOAN_ID,
                               P_FROM_DATE,
                               P_TO_DATE),
            0)
          ADD_INTEREST,
       0 ADD_TOTAL,
       NVL (
          (  NVL (
                (SELECT SUM (NVL (DR_AMOUNT, 0))
                   FROM ST_LOAN_DETAILS_GT
                  WHERE     LOAN_ID = XX_LOAN_DET.LOAN_ID
                        AND UPPER (CHARGE_TYPE) IN ('PAYMENT',
                                                    'PREPAYMENT ADJUSTMENT',
                                                    'GAIN')),
                0)
           - NVL (
                (SELECT SUM (NVL (CR_AMOUNT, 0))
                   FROM ST_LOAN_DETAILS_GT
                  WHERE     LOAN_ID = XX_LOAN_DET.LOAN_ID
                        AND UPPER (CHARGE_TYPE) = 'INTEREST'),
                0)
           - NVL (
                (SELECT SUM (NVL (CR_AMOUNT, 0))
                   FROM ST_LOAN_DETAILS_GT
                  WHERE     LOAN_ID = XX_LOAN_DET.LOAN_ID
                        AND UPPER (CHARGE_TYPE) IN ('EXCISE DUTY',
                                                    'LOSS',
                                                    'DISCOUNTING CHARGES')),
                0)),
          0)
          ADJST_PRINCIPLE,
       NVL (
          (SELECT SUM (NVL (ABS (CR_AMOUNT), 0))
             FROM ST_LOAN_DETAILS_GT
            WHERE     LOAN_ID = XX_LOAN_DET.LOAN_ID
                  AND UPPER (CHARGE_TYPE) IN ('INTEREST',
                                              'DISCOUNTING CHARGES')),
          0)
          ADJST_INTEREST,
       0 ADJST_TOTAL,
       0 NETT_PAY_PRINCIPLE,
       0 NETT_PAY_INTEREST,
       0 NETT_PAY_TOTAL,
       ST_GET_LOAN_PAYMENT_DATE (XX_LOAN_DET.LOAN_ID, P_TO_DATE) PAYMENT_DATE
  FROM XX_LOAN_DETAILS XX_LOAN_DET, 
       ST_LOAN_DETAILS_SUMMARY_X1 ST_LOAN_SUMM
 WHERE     ST_LOAN_SUMM.NETT_PAY_TOTAL <> 0
       AND ST_LOAN_SUMM.AS_OF_DATE = LAST_DAY (ADD_MONTHS (P_FROM_DATE, -1))
       AND ST_LOAN_SUMM.BANK_ID = XX_LOAN_DET.BANK_ID
       AND ST_LOAN_SUMM.LOAN_ID = XX_LOAN_DET.LOAN_ID
       AND XX_LOAN_DET.ORG_ID =  NVL (P_ORG_ID, XX_LOAN_DET.ORG_ID)
       AND XX_LOAN_DET.BANK_ID = NVL (P_BANK_ID, XX_LOAN_DET.BANK_ID)
       AND XX_LOAN_DET.LOAN_ID = NVL (P_LOAN_ID, XX_LOAN_DET.LOAN_ID)
UNION ALL
--------------

SELECT XX_LOAN_DET.ORG_ID,
       XX_LOAN_DET.BANK_NAME,
       XX_LOAN_DET.MAJOR_LOAN_TYPE,
       XX_LOAN_DET.LOAN_TYPE_CODE,
       XX_LOAN_DET.LOAN_ID,
       XX_LOAN_DET.LOAN_NUMBER,
       XX_LOAN_DET.OPENING_DATE,
       XX_LOAN_DET.LC_NUMBER,
       XX_LOAN_DET.LC_ID,
       XX_LOAN_DET.EFFECTIVE_START_DATE,
       XX_LOAN_DET.EFFECTIVE_END_DATE,
       XX_LOAN_DET.INTEREST_RATE,
       XX_LOAN_DET.CURRENCY_CODE,
       XX_LOAN_DET.LC_TYPE,
       XX_LOAN_DET.LOAN_AMOUNT,
       XX_LOAN_DET.FOREIGN_CURRENCY_RATE,
       XX_LOAN_DET.FOREIGN_CURRENCY_DATE,
       0 OB_PRINCIPLE,
       0 OB_INTEREST,
       0 OB_TOTAL,
       (NVL (
           (SELECT SUM (NVL (ABS (CR_AMOUNT), 0))
              FROM ST_LOAN_DETAILS_GT
             WHERE     LOAN_ID = XX_LOAN_DET.LOAN_ID
                   AND UPPER (CHARGE_TYPE) = 'PRINCIPLE'),
           0))
          ADD_PRINCIPLE,
       NVL (FN_GET_LOAN_INTER (P_BANK_ID,
                               P_LOAN_ID,
                               P_FROM_DATE,
                               P_TO_DATE),
            0)
          ADD_INTEREST,
       0 ADD_TOTAL,
       NVL (
          (  NVL (
                (SELECT SUM (NVL (DR_AMOUNT, 0))
                   FROM ST_LOAN_DETAILS_GT
                  WHERE     LOAN_ID = XX_LOAN_DET.LOAN_ID
                        AND UPPER (CHARGE_TYPE) IN ('PAYMENT',
                                                    'PREPAYMENT ADJUSTMENT',
                                                    'GAIN')),
                0)
           - NVL (
                (SELECT SUM (NVL (CR_AMOUNT, 0))
                   FROM ST_LOAN_DETAILS_GT
                  WHERE     LOAN_ID = XX_LOAN_DET.LOAN_ID
                        AND UPPER (CHARGE_TYPE) = 'INTEREST'),
                0)
           - NVL (
                (SELECT SUM (NVL (CR_AMOUNT, 0))
                   FROM ST_LOAN_DETAILS_GT
                  WHERE     LOAN_ID = XX_LOAN_DET.LOAN_ID
                        AND UPPER (CHARGE_TYPE) IN ('EXCISE DUTY',
                                                    'LOSS',
                                                    'DISCOUNTING CHARGES')),
                0)),
          0)
          ADJST_PRINCIPLE,
       NVL (
          (SELECT SUM (NVL (ABS (CR_AMOUNT), 0))
             FROM ST_LOAN_DETAILS_GT
            WHERE     LOAN_ID = XX_LOAN_DET.LOAN_ID
                  AND UPPER (CHARGE_TYPE) IN ('INTEREST',
                                              'DISCOUNTING CHARGES')),
          0)
          ADJST_INTEREST,
       0 ADJST_TOTAL,
       0 NETT_PAY_PRINCIPLE,
       0 NETT_PAY_INTEREST,
       0 NETT_PAY_TOTAL,
       ST_GET_LOAN_PAYMENT_DATE (XX_LOAN_DET.LOAN_ID, P_TO_DATE) PAYMENT_DATE
  FROM XX_LOAN_DETAILS XX_LOAN_DET --, ST_LOAN_DETAILS_SUMMARY_X1 st_loan_summ
 WHERE XX_LOAN_DET.ORG_ID = NVL (P_ORG_ID, XX_LOAN_DET.ORG_ID)
       AND XX_LOAN_DET.BANK_ID = NVL (P_BANK_ID, XX_LOAN_DET.BANK_ID)
       AND XX_LOAN_DET.LOAN_ID = NVL (P_LOAN_ID, XX_LOAN_DET.LOAN_ID)
       AND (XX_LOAN_DET.EFFECTIVE_START_DATE BETWEEN P_FROM_DATE
                                                 AND P_TO_DATE)
--------------

));


END;
/
