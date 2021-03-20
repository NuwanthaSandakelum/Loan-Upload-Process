DROP VIEW APPS.WG_LOAN_DETAILS_V;

/* Formatted on 8/28/2020 9:04:57 PM (QP5 v5.252.13127.32847) */
CREATE OR REPLACE FORCE VIEW APPS.WG_LOAN_DETAILS_V
(
   SL,
   ORG_ID,
   BAL_SEG,
   LOAN_ID,
   LOAN_NUMBER,
   BANK_ID,
   BANK_BRANCH_ID,
   LOAN_TYPE_CODE,
   LOAN_TYPE,
   OPENING_DATE,
   MATURITY_DATE,
   INTEREST_RATE,
   ACCOUNTING_DATE,
   VOUCHER,
   CHARGE_TYPE,
   DESCRIPTION,
   LC_NUMBER,
   DR_AMOUNT,
   CR_AMOUNT,
   FUNC_DR_AMOUNT,
   FUNC_CR_AMOUNT,
   MAJOR_LOAN_TYPE,
   CURRENCY_CODE,
   FOREIGN_CURRENCY_RATE,
   BANK_NAME,
   BANK_BRANCH_NAME,
   BANK_ACCOUNT_NAME,
   YTD_DAY,
   LC_ID
)
   BEQUEATH DEFINER
AS
   SELECT 1 SL,
          LD.ORG_ID,
          NVL (LD.COMPANY_CODE, XXOU.COMPANY_CODE) BAL_SEG,
          LD.LOAN_ID,
          LD.LOAN_NUMBER,
          LD.BANK_ID,
          LD.BANK_BRANCH_ID,
          LD.LOAN_TYPE_CODE,
          LD.LOAN_TYPE_DESC LOAN_TYPE,
          LD.OPENING_DATE,
          LD.EFFECTIVE_END_DATE MATURITY_DATE,
          0 INTEREST_RATE,
          --          TO_DATE ('31-JAN-2017') ACCOUNTING_DATE,
          TO_DATE ('31-DEC-2019') ACCOUNTING_DATE,
          NULL VOUCHER,
          'Opening' CHARGE_TYPE,
          --'Opening Balance on 31-JAN-2017'
          DESCRIPTION,
          LD.LC_NUMBER,
          0 DR_AMOUNT,
          ABS (NVL (LD.LOAN_AMOUNT, 0)) CR_AMOUNT,
          0,
          ABS (
             DECODE (CURRENCY_CODE,
                     'BDT', NVL (LD.LOAN_AMOUNT, 0),
                     (NVL (LD.LOAN_AMOUNT, 0) * FOREIGN_CURRENCY_RATE))),
          MAJOR_LOAN_TYPE,
          CURRENCY_CODE,
          FOREIGN_CURRENCY_RATE,
          BANK_NAME,
          BANK_BRANCH_NAME,
          BANK_ACCOUNT_NAME,
          NULL YTD_DAY,
          LD.LC_ID
     FROM APPS.XX_LOAN_DETAILS LD, APPS.XX_OU_BALSEG_V XXOU
    WHERE     LD.ORG_ID = XXOU.ORG_ID
          --          AND LD.CREATION_DATE >= TO_DATE ('31-JAN-2017')
          AND LD.LOAN_TYPE_CODE <> 'Liability on Export Bill'
          AND (   LD.DESCRIPTION = 'Opening Balance as on 31-JAN-2017'
               OR LD.DESCRIPTION = 'Open Data As on 31-DEC-2019')
   UNION ALL
   --Opening Loan Against Liabilities on export Bill
   SELECT 2 SL,
          LD.ORG_ID,
          NVL (LD.COMPANY_CODE, XXOU.COMPANY_CODE) BAL_SEG,
          LD.LOAN_ID,
          LD.LOAN_NUMBER,
          LD.BANK_ID,
          LD.BANK_BRANCH_ID,
          LD.LOAN_TYPE_CODE,
          LD.LOAN_TYPE_DESC LOAN_TYPE,
          LD.OPENING_DATE,
          LD.EFFECTIVE_END_DATE MATURITY_DATE,
          TO_NUMBER (NULL) INTEREST_RATE,
          TO_DATE (OPENING_DATE) ACCOUNTING_DATE,
          NULL VOUCHER,
          'Opening' CHARGE_TYPE,
          DESCRIPTION,
          LD.LC_NUMBER,
          0 DR_AMOUNT,
          LD.LOAN_AMOUNT CR_AMOUNT,
          0,
          LOAN_AMOUNT,
          MAJOR_LOAN_TYPE,
          CURRENCY_CODE,
          FOREIGN_CURRENCY_RATE,
          BANK_NAME,
          BANK_BRANCH_NAME,
          BANK_ACCOUNT_NAME,
          TO_NUMBER (NULL) YTD_DAY,
          LD.LC_ID
     FROM APPS.XX_LOAN_DETAILS LD, APPS.XX_OU_BALSEG_V XXOU
    WHERE     LD.ORG_ID = XXOU.ORG_ID
          AND LD.LOAN_TYPE_CODE = 'Liability on Export Bill'
          AND (   LD.DESCRIPTION = 'Opening Balance as on 31-JAN-2017'
               OR LD.DESCRIPTION = 'Open Data As on 31-DEC-2019')
   --          AND TO_DATE (OPENING_DATE) = TO_DATE ('31-JAN-2017')
   UNION ALL
   -------Loan Creation Part(Always Credit) from AP
   SELECT 3 SL,
          LD.ORG_ID,
          NVL (LD.COMPANY_CODE, XXOU.COMPANY_CODE) BAL_SEG,
          LD.LOAN_ID,
          LD.LOAN_NUMBER,
          LD.BANK_ID,
          LD.BANK_BRANCH_ID,
          LD.LOAN_TYPE_CODE,
          LD.LOAN_TYPE_DESC LOAN_TYPE,
          LD.OPENING_DATE,
          LD.EFFECTIVE_END_DATE MATURITY_DATE,
          0 INTEREST_RATE,
          PM.ACCOUNTING_DATE ACCOUNTING_DATE,
          AI.DOC_SEQUENCE_VALUE VOUCHER,
          'Principle' CHARGE_TYPE,
          CASE
             --WHEN aida.ATTRIBUTE_CATEGORY = 'Loan Details'
             --THEN
             -- AI.DESCRIPTION
          WHEN CK.ATTRIBUTE_CATEGORY = 'Loan Details' THEN CK.DESCRIPTION
             ELSE AI.DESCRIPTION
          END
             DESCRIPTION,
          LD.LC_NUMBER,
          0 DR_AMOUNT,
          ABS (NVL (CK.BASE_AMOUNT, CK.AMOUNT)) CR_AMOUNT,
          0,
          ABS (
             DECODE (LD.CURRENCY_CODE,
                     'BDT', NVL (PM.AMOUNT, 0),
                     (NVL (PM.AMOUNT, 0) * FOREIGN_CURRENCY_RATE))),
          MAJOR_LOAN_TYPE,
          LD.CURRENCY_CODE,
          FOREIGN_CURRENCY_RATE,
          BANK_NAME,
          BANK_BRANCH_NAME,
          LD.BANK_ACCOUNT_NAME,
          NULL YTD_DAY,
          LD.LC_ID
     FROM APPS.XX_LOAN_DETAILS LD,
          APPS.XX_OU_BALSEG_V XXOU,
          AP_INVOICES_ALL AI,
          --ap_invoice_distributions_all aida,
          APPS.AP_INVOICE_PAYMENTS_ALL PM,
          APPS.AP_CHECKS_ALL CK
    WHERE     LD.ORG_ID = XXOU.ORG_ID
          -- AND AI.INVOICE_ID = aida.INVOICE_ID
          AND AI.INVOICE_ID = PM.INVOICE_ID
          AND CK.CHECK_ID = PM.CHECK_ID
          --AND (LD.LOAN_ID = aida.attribute2 OR LD.LOAN_ID = CK.attribute2)
          AND LD.LOAN_ID = CK.attribute2
          --AND (   aida.ATTRIBUTE_CATEGORY = 'Loan Details' OR CK.ATTRIBUTE_CATEGORY = 'Loan Details')
          AND CK.ATTRIBUTE_CATEGORY = 'Loan Details'
          AND LD.LOAN_TYPE_CODE <> 'Liability on Export Bill'
          AND NVL (PM.REVERSAL_FLAG, 'N') <> 'Y'
          AND (CK.ATTRIBUTE3 != '1000'            --1000 code for 'Adjustment'
                                      OR CK.ATTRIBUTE4 != '1006') --1006 code for 'Provision'
          AND CK.ATTRIBUTE3 = '1005'               --1005 code for 'Principal'
   UNION ALL
   --LOAN CREATED FROM AR
   SELECT 3 SL,
          LD.ORG_ID,
          NVL (LD.COMPANY_CODE, XXOU.COMPANY_CODE) BAL_SEG,
          LD.LOAN_ID,
          LD.LOAN_NUMBER,
          LD.BANK_ID,
          LD.BANK_BRANCH_ID,
          LD.LOAN_TYPE_CODE,
          LD.LOAN_TYPE_DESC LOAN_TYPE,
          LD.OPENING_DATE,
          LD.EFFECTIVE_END_DATE MATURITY_DATE,
          0 INTEREST_RATE,
          RC.RECEIPT_DATE ACCOUNTING_DATE,
          RC.DOC_SEQUENCE_VALUE VOUCHER,
          'Principle' CHARGE_TYPE,
          LD.DESCRIPTION,
          LD.LC_NUMBER,
          0 DR_AMOUNT,
          RC.AMOUNT CR_AMOUNT,
          0 FUNC_DR_AMOUNT,
          ABS (
             DECODE (LD.CURRENCY_CODE,
                     'BDT', NVL (RC.AMOUNT, 0),
                     (NVL (RC.AMOUNT, 0) * FOREIGN_CURRENCY_RATE)))
             FUNC_CR_AMOUNT,
          MAJOR_LOAN_TYPE,
          LD.CURRENCY_CODE,
          FOREIGN_CURRENCY_RATE,
          BANK_NAME,
          BANK_BRANCH_NAME,
          LD.BANK_ACCOUNT_NAME,
          NULL YTD_DAY,
          LD.LC_ID
     FROM APPS.XX_LOAN_DETAILS LD,
          APPS.XX_OU_BALSEG_V XXOU,
          APPS.AR_CASH_RECEIPTS_ALL RC
    WHERE     LD.ORG_ID = XXOU.ORG_ID
          AND RC.ATTRIBUTE_CATEGORY = 'Loan Details'
          AND TO_CHAR (LD.LOAN_ID) = RC.ATTRIBUTE2
          AND LD.BANK_ID = RC.ATTRIBUTE1
          AND RC.ATTRIBUTE3 = 1005
          AND RC.REVERSAL_DATE IS NULL
   UNION ALL
   --LOAN CREATED FROM GL
   SELECT 3 SL,
          LD.ORG_ID,
          NVL (LD.COMPANY_CODE, XXOU.COMPANY_CODE) BAL_SEG,
          LD.LOAN_ID,
          LD.LOAN_NUMBER,
          LD.BANK_ID,
          LD.BANK_BRANCH_ID,
          LD.LOAN_TYPE_CODE,
          LD.LOAN_TYPE_DESC LOAN_TYPE,
          LD.OPENING_DATE,
          LD.EFFECTIVE_END_DATE MATURITY_DATE,
          0 INTEREST_RATE,
          JH.DEFAULT_EFFECTIVE_DATE ACCOUNTING_DATE,
          JH.DOC_SEQUENCE_VALUE VOUCHER,
          'Principle' CHARGE_TYPE,
          LD.DESCRIPTION,
          LD.LC_NUMBER,
          0 DR_AMOUNT,
          JL.ENTERED_CR CR_AMOUNT,
          0 FUNC_DR_AMOUNT,
          ACCOUNTED_CR FUNC_CR_AMOUNT,
          MAJOR_LOAN_TYPE,
          LD.CURRENCY_CODE,
          FOREIGN_CURRENCY_RATE,
          BANK_NAME,
          BANK_BRANCH_NAME,
          LD.BANK_ACCOUNT_NAME,
          NULL YTD_DAY,
          LD.LC_ID
     FROM APPS.XX_OU_BALSEG_V XXOU,
          APPS.XX_LOAN_DETAILS LD,
          GL_JE_HEADERS JH,
          GL_JE_LINES JL
    WHERE     LD.ORG_ID = XXOU.ORG_ID
          AND JH.JE_HEADER_ID = JL.JE_HEADER_ID
          AND JL.CONTEXT = 'Loan Detail'
          AND TO_CHAR (LD.LOAN_ID) = JL.ATTRIBUTE2
          AND JL.ATTRIBUTE3 = 1005
          AND JH.REVERSED_JE_HEADER_ID IS NULL
          AND NVL (ACCRUAL_REV_STATUS, 'N') <> 'R'
   UNION ALL
   --  LC Margin Part(Always Debit)
   SELECT 4 SL,
          LD.ORG_ID,
          NVL (LD.COMPANY_CODE, XXOU.COMPANY_CODE) BAL_SEG,
          LD.LOAN_ID,
          LD.LOAN_NUMBER,
          LD.BANK_ID,
          LD.BANK_BRANCH_ID,
          LD.LOAN_TYPE_CODE,
          LD.LOAN_TYPE_DESC LOAN_TYPE,
          LD.OPENING_DATE,
          LD.EFFECTIVE_END_DATE MATURITY_DATE,
          0 INTEREST_RATE,
          aida.ACCOUNTING_DATE ACCOUNTING_DATE,
          AI.DOC_SEQUENCE_VALUE VOUCHER,
          'Prepayment Adjustment' CHARGE_TYPE,
          aida.DESCRIPTION,
          LD.LC_NUMBER,
          ABS (NVL (aida.AMOUNT, 0)) DR_AMOUNT,
          0 CR_AMOUNT,
          0,
          ABS (
             DECODE (CURRENCY_CODE,
                     'BDT', NVL (aida.AMOUNT, 0),
                     (NVL (aida.AMOUNT, 0) * FOREIGN_CURRENCY_RATE))),
          MAJOR_LOAN_TYPE,
          CURRENCY_CODE,
          FOREIGN_CURRENCY_RATE,
          BANK_NAME,
          BANK_BRANCH_NAME,
          BANK_ACCOUNT_NAME,
          NULL YTD_DAY,
          LD.LC_ID
     FROM APPS.XX_LOAN_DETAILS LD,
          APPS.XX_OU_BALSEG_V XXOU,
          AP_INVOICES_ALL AI,
          ap_invoice_distributions_all aida
    WHERE     LD.ORG_ID = XXOU.ORG_ID
          AND AI.INVOICE_ID = aida.INVOICE_ID
          AND LD.LOAN_ID = aida.attribute2
          AND aida.ATTRIBUTE_CATEGORY = 'Loan Details'
          AND LD.LOAN_TYPE_CODE <> 'Liability on Export Bill'
          AND NVL (AIDA.REVERSAL_FLAG, 'N') <> 'Y'
          AND aida.ATTRIBUTE3 = '1000'             --100 code for 'Adjustment'
          AND aida.LINE_TYPE_LOOKUP_CODE = 'PREPAY'
          AND aida.PREPAY_DISTRIBUTION_ID IS NOT NULL
   UNION ALL
   --Interest Part (Always Credit)
   SELECT 5 SL,
          LD.ORG_ID,
          NVL (LD.COMPANY_CODE, XXOU.COMPANY_CODE) BAL_SEG,
          LD.LOAN_ID,
          LD.LOAN_NUMBER,
          LD.BANK_ID,
          LD.BANK_BRANCH_ID,
          LD.LOAN_TYPE_CODE,
          LD.LOAN_TYPE_DESC LOAN_TYPE,
          LD.OPENING_DATE,
          LD.EFFECTIVE_END_DATE MATURITY_DATE,
          0 INTEREST_RATE,
          aida.ACCOUNTING_DATE ACCOUNTING_DATE,
          AI.DOC_SEQUENCE_VALUE VOUCHER,
          'Interest' CHARGE_TYPE,
          aida.DESCRIPTION,
          LD.LC_NUMBER,
          0 DR_AMOUNT,
          ABS (NVL (aida.AMOUNT, 0)) CR_AMOUNT,
          0,
          ABS (
             DECODE (CURRENCY_CODE,
                     'BDT', NVL (aida.AMOUNT, 0),
                     (NVL (aida.AMOUNT, 0) * FOREIGN_CURRENCY_RATE))),
          MAJOR_LOAN_TYPE,
          CURRENCY_CODE,
          FOREIGN_CURRENCY_RATE,
          BANK_NAME,
          BANK_BRANCH_NAME,
          BANK_ACCOUNT_NAME,
          NULL YTD_DAY,
          LD.LC_ID
     FROM APPS.XX_LOAN_DETAILS LD,
          APPS.XX_OU_BALSEG_V XXOU,
          AP_INVOICES_ALL AI,
          ap_invoice_distributions_all aida
    WHERE     LD.ORG_ID = XXOU.ORG_ID
          AND AI.INVOICE_ID = aida.INVOICE_ID
          AND LD.LOAN_ID = aida.attribute2
          AND AIDA.ATTRIBUTE_CATEGORY = 'Loan Details'
          AND LD.LOAN_TYPE_CODE <> 'Liability on Export Bill'
          AND NVL (AIDA.REVERSAL_FLAG, 'N') <> 'Y'
          AND (AIDA.ATTRIBUTE3 != '1000'          --1000 code for 'Adjustment'
                                        OR aida.ATTRIBUTE4 != '1006' --1006 Code for 'Provision'
                                                                    )
          AND AIDA.ATTRIBUTE3 = '1002'               -- 1002 code for Interest
   UNION ALL
   --LOAN PROVISION PART (May Be Debit)
   SELECT 6 SL,
          LD.ORG_ID,
          NVL (LD.COMPANY_CODE, XXOU.COMPANY_CODE) BAL_SEG,
          LD.LOAN_ID,
          LD.LOAN_NUMBER,
          LD.BANK_ID,
          LD.BANK_BRANCH_ID,
          LD.LOAN_TYPE_CODE,
          LD.LOAN_TYPE_DESC LOAN_TYPE,
          LD.OPENING_DATE,
          LD.EFFECTIVE_END_DATE MATURITY_DATE,
          0 INTEREST_RATE,
          AIDA.ACCOUNTING_DATE ACCOUNTING_DATE,
          AI.DOC_SEQUENCE_VALUE VOUCHER,
          'Provision' CHARGE_TYPE,
          AIDA.DESCRIPTION,
          LD.LC_NUMBER,
          (GREATEST (NVL (AIDA.AMOUNT, 0), 0)) DR_AMOUNT,
          (0 - LEAST (NVL (AIDA.AMOUNT, 0), 0)) CR_AMOUNT,
          0,
          ABS (
             DECODE (CURRENCY_CODE,
                     'BDT', NVL (AIDA.AMOUNT, 0),
                     (NVL (AIDA.AMOUNT, 0) * FOREIGN_CURRENCY_RATE))),
          MAJOR_LOAN_TYPE,
          CURRENCY_CODE,
          FOREIGN_CURRENCY_RATE,
          BANK_NAME,
          BANK_BRANCH_NAME,
          BANK_ACCOUNT_NAME,
          NULL YTD_DAY,
          LD.LC_ID
     FROM APPS.XX_LOAN_DETAILS LD,
          APPS.XX_OU_BALSEG_V XXOU,
          AP_INVOICES_ALL AI,
          AP_INVOICE_DISTRIBUTIONS_ALL AIDA
    WHERE     LD.ORG_ID = XXOU.ORG_ID
          AND AI.INVOICE_ID = AIDA.INVOICE_ID
          AND LD.LOAN_ID = AIDA.attribute2
          AND AIDA.ATTRIBUTE_CATEGORY = 'Loan Details'
          AND LD.LOAN_TYPE_CODE <> 'Liability on Export Bill'
          AND NVL (AIDA.REVERSAL_FLAG, 'N') <> 'Y'
          AND (AIDA.ATTRIBUTE3 = '1002'             --1002 code for 'Interest'
                                       OR aida.ATTRIBUTE3 = '1000' --1000 code for 'Adjustment'
                                                                  )
          AND AIDA.ATTRIBUTE4 = '1006'             --1006 Code for 'Provision'
   UNION ALL
     --Deffered Principal Part
     SELECT 7 SL,
            LD.ORG_ID,
            NVL (LD.COMPANY_CODE, XXOU.COMPANY_CODE) BAL_SEG,
            LD.LOAN_ID,
            LD.LOAN_NUMBER,
            LD.BANK_ID,
            LD.BANK_BRANCH_ID,
            LD.LOAN_TYPE_CODE,
            LD.LOAN_TYPE_DESC LOAN_TYPE,
            LD.OPENING_DATE,
            NULL MATURITY_DATE,
            NULL INTEREST_RATE,
            AD.ACCOUNTING_DATE,
            AI.DOC_SEQUENCE_VALUE VOUCHER,
            'Principle',
            AI.DESCRIPTION,
            LD.LC_NUMBER,
            (0 - (LEAST (SUM (AD.AMOUNT), 0))) DR_AMOUNT,
            GREATEST (SUM (AD.AMOUNT), 0) CR_AMOUNT,
            (0 - (LEAST (SUM (NVL (AD.BASE_AMOUNT, AD.AMOUNT)), 0))),
            GREATEST (SUM (NVL (AD.BASE_AMOUNT, AD.AMOUNT)), 0),
            MAJOR_LOAN_TYPE,
            AI.INVOICE_CURRENCY_CODE CURRENCY_CODE,
            AI.EXCHANGE_RATE FOREIGN_CURRENCY_RATE,
            BANK_NAME,
            BANK_BRANCH_NAME,
            BANK_ACCOUNT_NAME,
            NULL YTD_DAY,
            LD.LC_ID
       FROM APPS.XX_LOAN_DETAILS LD,
            APPS.AP_INVOICES_ALL AI,
            AP_INVOICE_DISTRIBUTIONS_ALL AD,
            APPS.XX_OU_BALSEG_V XXOU
      WHERE     TO_CHAR (LD.LOAN_ID) = AI.ATTRIBUTE2
            AND LD.ORG_ID = XXOU.ORG_ID
            AND LD.LOAN_ID = AD.attribute2
            AND AI.INVOICE_ID = AD.INVOICE_ID
            AND AI.CANCELLED_DATE IS NULL
            AND LD.LOAN_TYPE_CODE <> 'Liability on Export Bill'
            AND AD.AMOUNT < 0
            AND NVL (REVERSAL_FLAG, 'N') <> 'Y'
            AND NVL (AD.LINE_TYPE_LOOKUP_CODE, 'XX') <> 'PREPAY'
            AND AI.ATTRIBUTE_CATEGORY = 'Loan Details'
            AND NVL (AI.INVOICE_TYPE_LOOKUP_CODE, 'XX') = 'STANDARD'
            AND NVL (AI.ATTRIBUTE2, -99) <> NVL (AD.ATTRIBUTE2, 99)
            AND NVL (LD.LOAN_TYPE_CODE, 'XX') = 'Deffered'
   GROUP BY LD.ORG_ID,
            LD.COMPANY_CODE,
            LD.LOAN_ID,
            LD.LOAN_NUMBER,
            LD.BANK_ID,
            LD.BANK_BRANCH_ID,
            LD.LOAN_TYPE_CODE,
            LD.LOAN_TYPE_DESC,
            LD.OPENING_DATE,
            AD.ACCOUNTING_DATE,
            AI.DOC_SEQUENCE_VALUE,
            AI.DESCRIPTION,
            LD.LC_NUMBER,
            MAJOR_LOAN_TYPE,
            AI.INVOICE_CURRENCY_CODE,
            AI.EXCHANGE_RATE,
            BANK_NAME,
            BANK_BRANCH_NAME,
            BANK_ACCOUNT_NAME,
            XXOU.COMPANY_CODE,
            LD.LC_ID
   UNION ALL
     --New Liabities on export Loan Entry  Debit or Credit memo  or Mixed
     SELECT 8 SL,
            LD.ORG_ID,
            NVL (LD.COMPANY_CODE, XXOU.COMPANY_CODE) BAL_SEG,
            LD.LOAN_ID,
            LD.LOAN_NUMBER,
            LD.BANK_ID,
            LD.BANK_BRANCH_ID,
            LD.LOAN_TYPE_CODE,
            LD.LOAN_TYPE_DESC LOAN_TYPE,
            LD.OPENING_DATE,
            LD.EFFECTIVE_END_DATE MATURITY_DATE,
            TO_NUMBER (NULL) INTEREST_RATE,
            AD.ACCOUNTING_DATE,
            AI.DOC_SEQUENCE_VALUE VOUCHER,
            'Principle',
            AI.DESCRIPTION,
            LD.LC_NUMBER,
            GREATEST (SUM (NVL (AD.BASE_AMOUNT, AD.AMOUNT)), 0) DR_AMOUNT,
            (0 - (LEAST (SUM (NVL (AD.BASE_AMOUNT, AD.AMOUNT)), 0))) CR_AMOUNT,
            GREATEST (SUM (NVL (AD.BASE_AMOUNT, AD.AMOUNT)), 0),
            (0 - (LEAST (SUM (NVL (AD.BASE_AMOUNT, AD.AMOUNT)), 0))),
            MAJOR_LOAN_TYPE,
            'BDT' CURRENCY_CODE,
            TO_NUMBER (NULL) FOREIGN_CURRENCY_RATE,
            BANK_NAME,
            BANK_BRANCH_NAME,
            BANK_ACCOUNT_NAME,
            TO_NUMBER (NULL) YTD_DAY,
            LD.LC_ID
       FROM APPS.XX_LOAN_DETAILS LD,
            AP_INVOICES_ALL AI,
            AP_INVOICE_DISTRIBUTIONS_ALL AD,
            APPS.XX_OU_BALSEG_V XXOU
      WHERE     (   TO_CHAR (LD.LOAN_ID) = AI.ATTRIBUTE2
                 OR TO_CHAR (LD.LOAN_ID) = AD.ATTRIBUTE2)
            AND AI.INVOICE_ID = AD.INVOICE_ID
            AND LD.ORG_ID = XXOU.ORG_ID
            AND AI.CANCELLED_DATE IS NULL
            AND APPS.SOFTLN_COM_PKG.GET_SEGMENT_VALUE_FROM_CCID (
                   DIST_CODE_COMBINATION_ID,
                   4) = '22060201'
            AND NVL (REVERSAL_FLAG, 'N') <> 'Y'
            AND AD.AMOUNT < 0
            AND LD.LOAN_TYPE_CODE = 'Liability on Export Bill'
            AND (   AI.ATTRIBUTE_CATEGORY = 'Loan Details'
                 OR AD.ATTRIBUTE_CATEGORY = 'Loan Details')
            AND NVL (AI.INVOICE_TYPE_LOOKUP_CODE, 'XX') IN ('DEBIT',
                                                            'CREDIT',
                                                            'MIXED')
   GROUP BY LD.ORG_ID,
            LD.COMPANY_CODE,
            LD.LOAN_ID,
            LD.LOAN_NUMBER,
            LD.BANK_ID,
            LD.BANK_BRANCH_ID,
            LD.LOAN_TYPE_CODE,
            LD.LOAN_TYPE_DESC,
            LD.OPENING_DATE,
            LD.EFFECTIVE_END_DATE,
            AD.ACCOUNTING_DATE,
            AI.DOC_SEQUENCE_VALUE,
            AI.DESCRIPTION,
            LD.LC_NUMBER,
            MAJOR_LOAN_TYPE,
            AI.INVOICE_CURRENCY_CODE,
            AI.EXCHANGE_RATE,
            BANK_NAME,
            BANK_BRANCH_NAME,
            BANK_ACCOUNT_NAME,
            XXOU.COMPANY_CODE,
            LD.LC_ID
   UNION ALL
     --Loss Part in Distribution Level(Always Credit)
     SELECT 9 SL,
            LD.ORG_ID,
            NVL (LD.COMPANY_CODE, XXOU.COMPANY_CODE) BAL_SEG,
            LD.LOAN_ID,
            LD.LOAN_NUMBER,
            LD.BANK_ID,
            LD.BANK_BRANCH_ID,
            LD.LOAN_TYPE_CODE,
            LD.LOAN_TYPE_DESC LOAN_TYPE,
            LD.OPENING_DATE,
            LD.EFFECTIVE_END_DATE MATURITY_DATE,
            NULL INTEREST_RATE,
            AD.ACCOUNTING_DATE,
            AI.DOC_SEQUENCE_VALUE VOUCHER,
            'Loss',
            AD.DESCRIPTION,
            LD.LC_NUMBER,
            (0 - (LEAST (SUM (AD.AMOUNT), 0))) DR_AMOUNT,
            GREATEST (SUM (AD.AMOUNT), 0) CR_AMOUNT,
            GREATEST (SUM (NVL (AD.BASE_AMOUNT, AD.AMOUNT)), 0),
            (0 - (LEAST (SUM (NVL (AD.BASE_AMOUNT, AD.AMOUNT)), 0))),
            MAJOR_LOAN_TYPE,
            AI.INVOICE_CURRENCY_CODE CURRENCY_CODE,
            AI.EXCHANGE_RATE FOREIGN_CURRENCY_RATE,
            BANK_NAME,
            BANK_BRANCH_NAME,
            BANK_ACCOUNT_NAME,
            NULL YTD_DAY,
            LD.LC_ID
       FROM APPS.XX_LOAN_DETAILS LD,
            AP_INVOICES_ALL AI,
            AP_INVOICE_DISTRIBUTIONS_ALL AD,
            APPS.XX_OU_BALSEG_V XXOU
      WHERE     LD.LOAN_ID = AD.ATTRIBUTE2
            AND AI.INVOICE_ID = AD.INVOICE_ID
            AND AD.ORG_ID = XXOU.ORG_ID
            AND AI.CANCELLED_DATE IS NULL
            AND NVL (AD.REVERSAL_FLAG, 'N') <> 'Y'
            AND AD.ATTRIBUTE_CATEGORY = 'Loan Details'
            AND AD.ATTRIBUTE3 = '1003'                  --1003 code for 'Loss'
            AND NVL (REVERSAL_FLAG, 'N') <> 'Y'
            AND LD.LOAN_TYPE_CODE <> 'Liability on Export Bill'
   GROUP BY LD.ORG_ID,
            LD.COMPANY_CODE,
            LD.LOAN_ID,
            LD.LOAN_NUMBER,
            LD.BANK_ID,
            LD.BANK_BRANCH_ID,
            LD.LOAN_TYPE_CODE,
            LD.LOAN_TYPE_DESC,
            LD.OPENING_DATE,
            LD.EFFECTIVE_END_DATE,
            AD.ACCOUNTING_DATE,
            AI.DOC_SEQUENCE_VALUE,
            AD.DESCRIPTION,
            LD.LC_NUMBER,
            MAJOR_LOAN_TYPE,
            AI.INVOICE_CURRENCY_CODE,
            AI.EXCHANGE_RATE,
            BANK_NAME,
            BANK_BRANCH_NAME,
            BANK_ACCOUNT_NAME,
            XXOU.COMPANY_CODE,
            LD.LC_ID
   UNION ALL
     --Excise Duty Distribution Level
     SELECT 10 SL,
            LD.ORG_ID,
            NVL (LD.COMPANY_CODE, XXOU.COMPANY_CODE) BAL_SEG,
            LD.LOAN_ID,
            LD.LOAN_NUMBER,
            LD.BANK_ID,
            LD.BANK_BRANCH_ID,
            LD.LOAN_TYPE_CODE,
            LD.LOAN_TYPE_DESC LOAN_TYPE,
            LD.OPENING_DATE,
            LD.EFFECTIVE_END_DATE MATURITY_DATE,
            NULL INTEREST_RATE,
            AD.ACCOUNTING_DATE,
            AI.DOC_SEQUENCE_VALUE VOUCHER,
            'Excise Duty',
            AD.DESCRIPTION,
            LD.LC_NUMBER,
            (0 - (LEAST (SUM (AD.AMOUNT), 0))) DR_AMOUNT,
            GREATEST (SUM (AD.AMOUNT), 0) CR_AMOUNT,
            GREATEST (SUM (NVL (AD.BASE_AMOUNT, AD.AMOUNT)), 0),
            (0 - (LEAST (SUM (NVL (AD.BASE_AMOUNT, AD.AMOUNT)), 0))),
            MAJOR_LOAN_TYPE,
            AI.INVOICE_CURRENCY_CODE CURRENCY_CODE,
            AI.EXCHANGE_RATE FOREIGN_CURRENCY_RATE,
            BANK_NAME,
            BANK_BRANCH_NAME,
            BANK_ACCOUNT_NAME,
            NULL YTD_DAY,
            LD.LC_ID
       FROM APPS.XX_LOAN_DETAILS LD,
            AP_INVOICES_ALL AI,
            AP_INVOICE_DISTRIBUTIONS_ALL AD,
            APPS.XX_OU_BALSEG_V XXOU                                      ---,
      WHERE     LD.LOAN_ID = AD.ATTRIBUTE2
            AND AI.INVOICE_ID = AD.INVOICE_ID
            AND AD.ORG_ID = XXOU.ORG_ID
            AND AI.CANCELLED_DATE IS NULL
            AND NVL (AD.REVERSAL_FLAG, 'N') <> 'Y'
            AND AD.ATTRIBUTE_CATEGORY = 'Loan Details'
            AND AD.ATTRIBUTE3 = '1008'           -- 1008 code for'Excise Duty'
            AND NVL (REVERSAL_FLAG, 'N') <> 'Y'
            AND LD.LOAN_TYPE_CODE <> 'Liability on Export Bill'
   GROUP BY LD.ORG_ID,
            LD.COMPANY_CODE,
            LD.LOAN_ID,
            LD.LOAN_NUMBER,
            LD.BANK_ID,
            LD.BANK_BRANCH_ID,
            LD.LOAN_TYPE_CODE,
            LD.LOAN_TYPE_DESC,
            LD.OPENING_DATE,
            LD.EFFECTIVE_END_DATE,
            AD.ACCOUNTING_DATE,
            AI.DOC_SEQUENCE_VALUE,
            AD.DESCRIPTION,
            LD.LC_NUMBER,
            MAJOR_LOAN_TYPE,
            AI.INVOICE_CURRENCY_CODE,
            AI.EXCHANGE_RATE,
            BANK_NAME,
            BANK_BRANCH_NAME,
            BANK_ACCOUNT_NAME,
            XXOU.COMPANY_CODE,
            LD.LC_ID
   UNION ALL
     --Discounting Charges Distribution Level
     SELECT 11 SL,
            LD.ORG_ID,
            NVL (LD.COMPANY_CODE, XXOU.COMPANY_CODE) BAL_SEG,
            LD.LOAN_ID,
            LD.LOAN_NUMBER,
            LD.BANK_ID,
            LD.BANK_BRANCH_ID,
            LD.LOAN_TYPE_CODE,
            LD.LOAN_TYPE_DESC LOAN_TYPE,
            LD.OPENING_DATE,
            LD.EFFECTIVE_END_DATE MATURITY_DATE,
            NULL INTEREST_RATE,
            AD.ACCOUNTING_DATE,
            AI.DOC_SEQUENCE_VALUE VOUCHER,
            'Discounting Charges',
            AD.DESCRIPTION,
            LD.LC_NUMBER,
            (0 - (LEAST (SUM (AD.AMOUNT), 0))) DR_AMOUNT,
            GREATEST (SUM (AD.AMOUNT), 0) CR_AMOUNT,
            GREATEST (SUM (NVL (AD.BASE_AMOUNT, AD.AMOUNT)), 0),
            (0 - (LEAST (SUM (NVL (AD.BASE_AMOUNT, AD.AMOUNT)), 0))),
            MAJOR_LOAN_TYPE,
            AI.INVOICE_CURRENCY_CODE CURRENCY_CODE,
            AI.EXCHANGE_RATE FOREIGN_CURRENCY_RATE,
            BANK_NAME,
            BANK_BRANCH_NAME,
            BANK_ACCOUNT_NAME,
            NULL YTD_DAY,
            LD.LC_ID
       FROM APPS.XX_LOAN_DETAILS LD,
            AP_INVOICES_ALL AI,
            AP_INVOICE_DISTRIBUTIONS_ALL AD,
            APPS.XX_OU_BALSEG_V XXOU                                      ---,
      WHERE     LD.LOAN_ID = AD.ATTRIBUTE2
            AND AI.INVOICE_ID = AD.INVOICE_ID
            AND AD.ORG_ID = XXOU.ORG_ID
            AND AI.CANCELLED_DATE IS NULL
            AND NVL (AD.REVERSAL_FLAG, 'N') <> 'Y'
            AND AD.ATTRIBUTE_CATEGORY = 'Loan Details'
            AND AD.ATTRIBUTE3 = '1007'    --1007 Code for Discounting Charges'
            AND NVL (REVERSAL_FLAG, 'N') <> 'Y'
            AND LD.LOAN_TYPE_CODE <> 'Liability on Export Bill'
   GROUP BY LD.ORG_ID,
            LD.COMPANY_CODE,
            LD.LOAN_ID,
            LD.LOAN_NUMBER,
            LD.BANK_ID,
            LD.BANK_BRANCH_ID,
            LD.LOAN_TYPE_CODE,
            LD.LOAN_TYPE_DESC,
            LD.OPENING_DATE,
            LD.EFFECTIVE_END_DATE,
            AD.ACCOUNTING_DATE,
            AI.DOC_SEQUENCE_VALUE,
            AD.DESCRIPTION,
            LD.LC_NUMBER,
            MAJOR_LOAN_TYPE,
            AI.INVOICE_CURRENCY_CODE,
            AI.EXCHANGE_RATE,
            BANK_NAME,
            BANK_BRANCH_NAME,
            BANK_ACCOUNT_NAME,
            XXOU.COMPANY_CODE,
            LD.LC_ID
   UNION ALL
     ----Query for Bank Charge
     SELECT 12 SL,
            LD.ORG_ID,
            NVL (LD.COMPANY_CODE, XXOU.COMPANY_CODE) BAL_SEG,
            LD.LOAN_ID,
            LD.LOAN_NUMBER,
            LD.BANK_ID,
            LD.BANK_BRANCH_ID,
            LD.LOAN_TYPE_CODE,
            LD.LOAN_TYPE_DESC LOAN_TYPE,
            LD.OPENING_DATE,
            LD.EFFECTIVE_END_DATE MATURITY_DATE,
            NULL INTEREST_RATE,
            AD.ACCOUNTING_DATE,
            AI.DOC_SEQUENCE_VALUE VOUCHER,
            'Bank Charge',
            AD.DESCRIPTION,
            LD.LC_NUMBER,
            (0 - (LEAST (SUM (AD.AMOUNT), 0))) DR_AMOUNT,
            GREATEST (SUM (AD.AMOUNT), 0) CR_AMOUNT,
            GREATEST (SUM (NVL (AD.BASE_AMOUNT, AD.AMOUNT)), 0),
            (0 - (LEAST (SUM (NVL (AD.BASE_AMOUNT, AD.AMOUNT)), 0))),
            MAJOR_LOAN_TYPE,
            AI.INVOICE_CURRENCY_CODE CURRENCY_CODE,
            AI.EXCHANGE_RATE FOREIGN_CURRENCY_RATE,
            BANK_NAME,
            BANK_BRANCH_NAME,
            BANK_ACCOUNT_NAME,
            NULL YTD_DAY,
            LD.LC_ID
       FROM APPS.XX_LOAN_DETAILS LD,
            AP_INVOICES_ALL AI,
            AP_INVOICE_DISTRIBUTIONS_ALL AD,
            APPS.XX_OU_BALSEG_V XXOU
      WHERE     LD.LOAN_ID = AD.ATTRIBUTE2
            AND AI.INVOICE_ID = AD.INVOICE_ID
            AND AD.ORG_ID = XXOU.ORG_ID
            AND AI.CANCELLED_DATE IS NULL
            AND NVL (AD.REVERSAL_FLAG, 'N') <> 'Y'
            AND AD.ATTRIBUTE_CATEGORY = 'Loan Details'
            AND AD.ATTRIBUTE3 = '1009'           --1009 code for 'Bank Charge'
            AND LD.LOAN_TYPE_CODE <> 'Liability on Export Bill'
   GROUP BY LD.ORG_ID,
            LD.COMPANY_CODE,
            LD.LOAN_ID,
            LD.LOAN_NUMBER,
            LD.BANK_ID,
            LD.BANK_BRANCH_ID,
            LD.LOAN_TYPE_CODE,
            LD.LOAN_TYPE_DESC,
            LD.OPENING_DATE,
            LD.EFFECTIVE_END_DATE,
            AD.ACCOUNTING_DATE,
            AI.DOC_SEQUENCE_VALUE,
            AD.DESCRIPTION,
            LD.LC_NUMBER,
            MAJOR_LOAN_TYPE,
            AI.INVOICE_CURRENCY_CODE,
            AI.EXCHANGE_RATE,
            BANK_NAME,
            BANK_BRANCH_NAME,
            BANK_ACCOUNT_NAME,
            XXOU.COMPANY_CODE,
            LD.LC_ID
   UNION ALL
     --Gain Distribution Level
     SELECT 13 SL,
            LD.ORG_ID,
            NVL (LD.COMPANY_CODE, XXOU.COMPANY_CODE) BAL_SEG,
            LD.LOAN_ID,
            LD.LOAN_NUMBER,
            LD.BANK_ID,
            LD.BANK_BRANCH_ID,
            LD.LOAN_TYPE_CODE,
            LD.LOAN_TYPE_DESC LOAN_TYPE,
            LD.OPENING_DATE,
            LD.EFFECTIVE_END_DATE MATURITY_DATE,
            NULL INTEREST_RATE,
            AD.ACCOUNTING_DATE,
            AI.DOC_SEQUENCE_VALUE VOUCHER,
            'Gain',
            AD.DESCRIPTION,
            LD.LC_NUMBER,
            (0 - (LEAST (SUM (AD.AMOUNT), 0))) DR_AMOUNT,
            GREATEST (SUM (AD.AMOUNT), 0) CR_AMOUNT,
            GREATEST (SUM (NVL (AD.BASE_AMOUNT, AD.AMOUNT)), 0),
            (0 - (LEAST (SUM (NVL (AD.BASE_AMOUNT, AD.AMOUNT)), 0))),
            MAJOR_LOAN_TYPE,
            AI.INVOICE_CURRENCY_CODE CURRENCY_CODE,
            AI.EXCHANGE_RATE FOREIGN_CURRENCY_RATE,
            BANK_NAME,
            BANK_BRANCH_NAME,
            BANK_ACCOUNT_NAME,
            NULL YTD_DAY,
            LD.LC_ID
       FROM APPS.XX_LOAN_DETAILS LD,
            AP_INVOICES_ALL AI,
            AP_INVOICE_DISTRIBUTIONS_ALL AD,
            APPS.XX_OU_BALSEG_V XXOU                                      ---,
      WHERE     LD.LOAN_ID = AD.ATTRIBUTE2
            AND AI.INVOICE_ID = AD.INVOICE_ID
            AND AD.ORG_ID = XXOU.ORG_ID
            AND AI.CANCELLED_DATE IS NULL
            AND NVL (AD.REVERSAL_FLAG, 'N') <> 'Y'
            AND AD.ATTRIBUTE_CATEGORY = 'Loan Details'
            AND AD.ATTRIBUTE3 = '1001'                   --1001 Code for'Gain'
            AND LD.LOAN_TYPE_CODE <> 'Liability on Export Bill'
   GROUP BY LD.ORG_ID,
            LD.COMPANY_CODE,
            LD.LOAN_ID,
            LD.LOAN_NUMBER,
            LD.BANK_ID,
            LD.BANK_BRANCH_ID,
            LD.LOAN_TYPE_CODE,
            LD.LOAN_TYPE_DESC,
            LD.OPENING_DATE,
            LD.EFFECTIVE_END_DATE,
            AD.ACCOUNTING_DATE,
            AI.DOC_SEQUENCE_VALUE,
            AD.DESCRIPTION,
            LD.LC_NUMBER,
            MAJOR_LOAN_TYPE,
            AI.INVOICE_CURRENCY_CODE,
            AI.EXCHANGE_RATE,
            BANK_NAME,
            BANK_BRANCH_NAME,
            BANK_ACCOUNT_NAME,
            XXOU.COMPANY_CODE,
            LD.LC_ID
   UNION ALL
   --Loan Reduces for Different Reason
   SELECT 14 SL,
          LD.ORG_ID,
          NVL (LD.COMPANY_CODE, XXOU.COMPANY_CODE) BAL_SEG,
          LD.LOAN_ID,
          LD.LOAN_NUMBER,
          LD.BANK_ID,
          LD.BANK_BRANCH_ID,
          LD.LOAN_TYPE_CODE,
          LD.LOAN_TYPE_DESC LOAN_TYPE,
          LD.OPENING_DATE,
          LD.EFFECTIVE_END_DATE MATURITY_DATE,
          TO_NUMBER (NULL) INTEREST_RATE,
          AD.ACCOUNTING_DATE,
          AI.DOC_SEQUENCE_VALUE VOUCHER,
          'Interest Refund',
          AD.DESCRIPTION,
          LD.LC_NUMBER,
          GREATEST (AD.AMOUNT, 0) DR_AMOUNT,
          (0 - (LEAST (AD.AMOUNT, 0))) CR_AMOUNT,
          GREATEST (NVL (AD.BASE_AMOUNT, AD.AMOUNT), 0),
          (0 - (LEAST (NVL (AD.BASE_AMOUNT, AD.AMOUNT), 0))),
          MAJOR_LOAN_TYPE,
          AI.INVOICE_CURRENCY_CODE CURRENCY_CODE,
          AI.EXCHANGE_RATE FOREIGN_CURRENCY_RATE,
          BANK_NAME,
          BANK_BRANCH_NAME,
          BANK_ACCOUNT_NAME,
          NULL YTD_DAY,
          LD.LC_ID
     FROM APPS.XX_LOAN_DETAILS LD,
          AP_INVOICES_ALL AI,
          AP_INVOICE_DISTRIBUTIONS_ALL AD,
          APPS.XX_OU_BALSEG_V XXOU                                        ---,
    WHERE     TO_CHAR (LD.LOAN_ID) = AD.ATTRIBUTE2
          AND AI.INVOICE_ID = AD.INVOICE_ID
          AND AI.CANCELLED_DATE IS NULL
          AND NVL (AD.REVERSAL_FLAG, 'N') <> 'Y'
          AND AD.ATTRIBUTE_CATEGORY = 'Loan Details'
          AND AD.ATTRIBUTE3 = '1010'             -- Code for('Interest Refund'
          AND LD.ORG_ID = XXOU.ORG_ID
          --AND NVL (REVERSAL_FLAG, 'N') <> 'Y'
          AND LD.LOAN_TYPE_CODE <> 'Liability on Export Bill'
   UNION ALL
   --Adjustment entry of loan by another loan
   SELECT 15 SL,
          LD.ORG_ID,
          NVL (LD.COMPANY_CODE, XXOU.COMPANY_CODE) BAL_SEG,
          LD.LOAN_ID,
          LD.LOAN_NUMBER,
          LD.BANK_ID,
          LD.BANK_BRANCH_ID,
          LD.LOAN_TYPE_CODE,
          LD.LOAN_TYPE_DESC LOAN_TYPE,
          LD.OPENING_DATE,
          LD.EFFECTIVE_END_DATE MATURITY_DATE,
          TO_NUMBER (NULL) INTEREST_RATE,
          AD.ACCOUNTING_DATE,
          AI.DOC_SEQUENCE_VALUE VOUCHER,
          'Adjustment',                                       --AD.ATTRIBUTE3,
          AD.DESCRIPTION,
          LD.LC_NUMBER,
          GREATEST (NVL (AD.AMOUNT, 0)),
          (0 - (LEAST (AD.AMOUNT, 0))),
          GREATEST (NVL (AD.BASE_AMOUNT, AD.AMOUNT), 0),
          (0 - (LEAST (NVL (AD.BASE_AMOUNT, AD.AMOUNT), 0))),
          MAJOR_LOAN_TYPE,
          AI.INVOICE_CURRENCY_CODE CURRENCY_CODE,
          AI.EXCHANGE_RATE FOREIGN_CURRENCY_RATE,
          BANK_NAME,
          BANK_BRANCH_NAME,
          LD.BANK_ACCOUNT_NAME,
          NULL YTD_DAY,
          LD.LC_ID
     FROM APPS.XX_LOAN_DETAILS LD,
          AP_INVOICES_ALL AI,
          AP_INVOICE_DISTRIBUTIONS_ALL AD,
          APPS.AP_SUPPLIERS AV,
          APPS.AP_SUPPLIER_SITES_ALL ST,
          APPS.XX_OU_BALSEG_V XXOU                                       ----,
    WHERE     TO_CHAR (LD.LOAN_ID) = AD.ATTRIBUTE2
          AND AI.INVOICE_ID = AD.INVOICE_ID
          AND AI.CANCELLED_DATE IS NULL
          AND AI.VENDOR_ID = AV.VENDOR_ID
          AND AV.VENDOR_ID = ST.VENDOR_ID
          AND AI.VENDOR_SITE_ID = ST.VENDOR_SITE_ID
          AND NVL (AD.REVERSAL_FLAG, 'N') <> 'Y'
          AND AD.ATTRIBUTE_CATEGORY = 'Loan Details'
          AND AD.ATTRIBUTE3 = '1000'              --1000 Code for 'Adjustment'
          AND NVL (AI.ATTRIBUTE_CATEGORY, 'XX') = 'Loan Details'
          AND NVL (AI.ATTRIBUTE2, 'XX') <> NVL (AD.ATTRIBUTE2, 'XX')
          AND LD.LOAN_TYPE_CODE <> 'Liability on Export Bill'
          AND LD.ORG_ID = XXOU.ORG_ID
   UNION ALL
     -- Payment Query
     SELECT 16 SL,
            LD.ORG_ID ORG_ID,
            NVL (MAX (LD.COMPANY_CODE), MAX (XXOU.COMPANY_CODE)) BAL_SEG,
            LD.LOAN_ID,
            LD.LOAN_NUMBER,
            LD.BANK_ID BANK_ID,
            LD.BANK_BRANCH_ID BANK_BRANCH_ID,
            LD.LOAN_TYPE_CODE LOAN_TYPE_CODE,
            LD.LOAN_TYPE_DESC LOAN_TYPE,
            LD.OPENING_DATE OPENING_DATE,
            LD.EFFECTIVE_END_DATE MATURITY_DATE,
            TO_NUMBER (NULL) INTEREST_RATE,
            CK.CHECK_DATE CHECK_DATE,
            MAX (CK.DOC_SEQUENCE_VALUE) DOC_SEQUENCE_VALUE,
            'Payment',
            MAX (CK.DESCRIPTION) DESCRIPTION,
            LD.LC_NUMBER,
            -- (NVL (AD.AMOUNT, 0) * nvl(ai.exchange_rate,1) ) DR_AMOUNT,
            (CASE
                WHEN LD.LOAN_TYPE_CODE = 'Term Loan - Foreign'
                THEN
                   NVL (AD.AMOUNT, 0)
                ELSE
                   (NVL (AD.AMOUNT, 0) * NVL (ai.exchange_rate, 1))
             END)
               DR_AMOUNT,
            0 CR_AMOUNT,
            0,
            0,
            MAJOR_LOAN_TYPE MAJOR_LOAN_TYPE,
            CK.CURRENCY_CODE CURRENCY_CODE,
            --CK.EXCHANGE_RATE FOREIGN_CURRENCY_RATE,
            ai.exchange_rate FOREIGN_CURRENCY_RATE,
            BANK_NAME BANK_NAME,
            BANK_BRANCH_NAME BANK_BRANCH_NAME,
            LD.BANK_ACCOUNT_NAME BANK_ACCOUNT_NAME,
            NULL YTD_DAY,
            LD.LC_ID
       FROM APPS.XX_LOAN_DETAILS LD,
            AP_INVOICES_ALL AI,
            AP_INVOICE_DISTRIBUTIONS_ALL AD,
            APPS.AP_INVOICE_PAYMENTS_ALL PM,
            APPS.AP_CHECKS_ALL CK,
            APPS.XX_OU_BALSEG_V XXOU
      WHERE     LD.LOAN_ID = AD.ATTRIBUTE2(+)
            AND AI.INVOICE_ID = AD.INVOICE_ID
            AND AI.INVOICE_ID = PM.INVOICE_ID(+)
            AND PM.CHECK_ID = CK.CHECK_ID
            AND AI.CANCELLED_DATE IS NULL
            AND NVL (AD.REVERSAL_FLAG, 'N') <> 'Y'
            AND NVL (PM.REVERSAL_FLAG, 'N') <> 'Y'
            AND NVL (CK.STATUS_LOOKUP_CODE, 'XX') <> 'VOIDED'
            AND AD.ATTRIBUTE_CATEGORY = 'Loan Details'
            AND LD.ORG_ID = XXOU.ORG_ID
            AND AI.INVOICE_TYPE_LOOKUP_CODE IN ('STANDARD', 'MIXED')
            AND AD.LINE_TYPE_LOOKUP_CODE <> 'PREPAY'
            AND LD.LOAN_TYPE_CODE <> 'Liability on Export Bill'
            AND UPPER (AD.ATTRIBUTE7) = 'YES'
            AND AD.ATTRIBUTE3 IN ('1000',
                                  '1001',
                                  '1002',
                                  '1003',
                                  '1004',
                                  '1005',
                                  '1006',
                                  '1007',
                                  '1008')
            AND ai.doc_sequence_value IN (  SELECT ai2.doc_sequence_value
                                              FROM AP_INVOICE_DISTRIBUTIONS_ALL AD2,
                                                   AP_INVOICES_ALL AI2
                                             WHERE     AD2.ATTRIBUTE_CATEGORY =
                                                          'Loan Details'
                                                   AND Ad2.INVOICE_ID =
                                                          AI2.INVOICE_ID
                                                   AND AI2.CANCELLED_DATE IS NULL
                                                   AND NVL (AD2.REVERSAL_FLAG,
                                                            'N') <> 'Y'
                                          GROUP BY ai2.doc_sequence_value,
                                                   AD2.invoice_id
                                            HAVING COUNT (
                                                      DISTINCT AD2.ATTRIBUTE2) >
                                                      1)
   GROUP BY LD.ORG_ID,
            LD.BANK_ID,
            AI.INVOICE_ID,
            LD.LOAN_ID,
            LD.LOAN_NUMBER,
            LD.BANK_BRANCH_ID,
            LD.LOAN_TYPE_CODE,
            LD.LOAN_TYPE_DESC,
            LD.OPENING_DATE,
            LD.EFFECTIVE_END_DATE,
            LD.LC_NUMBER,
            CK.CHECK_DATE,
            CK.AMOUNT,
            PM.AMOUNT,
            AD.AMOUNT,
            MAJOR_LOAN_TYPE,
            CK.CURRENCY_CODE,
            ai.exchange_rate,
            BANK_NAME,
            BANK_BRANCH_NAME,
            LD.BANK_ACCOUNT_NAME,
            CHECK_NUMBER,
            LD.LC_ID
   UNION ALL
     --Payment Part (Always Debit)  -- changed to add exchange rate
     SELECT DISTINCT
            17 SL,
            LD.ORG_ID ORG_ID,
            NVL (MAX (LD.COMPANY_CODE), MAX (XXOU.COMPANY_CODE)) BAL_SEG,
            LD.LOAN_ID,
            LD.LOAN_NUMBER,
            LD.BANK_ID BANK_ID,
            LD.BANK_BRANCH_ID BANK_BRANCH_ID,
            LD.LOAN_TYPE_CODE LOAN_TYPE_CODE,
            LD.LOAN_TYPE_DESC LOAN_TYPE,
            LD.OPENING_DATE OPENING_DATE,
            LD.EFFECTIVE_END_DATE MATURITY_DATE,
            TO_NUMBER (NULL) INTEREST_RATE,
            CK.CHECK_DATE CHECK_DATE,
            MAX (CK.DOC_SEQUENCE_VALUE) DOC_SEQUENCE_VALUE,
            'Payment',
            MAX (CK.DESCRIPTION) DESCRIPTION,
            LD.LC_NUMBER,
            --(LEAST ( (NVL (CK.AMOUNT, 0)), (NVL (PM.AMOUNT, 0))) * nvl(ai.exchange_rate,1) ) DR_AMOUNT,
            (CASE
                WHEN LD.LOAN_TYPE_CODE = 'Term Loan - Foreign'
                THEN
                   LEAST ( (NVL (CK.AMOUNT, 0)), (NVL (PM.AMOUNT, 0)))
                ELSE
                   (  LEAST ( (NVL (CK.AMOUNT, 0)), (NVL (PM.AMOUNT, 0)))
                    * NVL (ai.exchange_rate, 1))
             END)
               DR_AMOUNT,
            0 CR_AMOUNT,
            0,
            0,
            MAJOR_LOAN_TYPE MAJOR_LOAN_TYPE,
            CK.CURRENCY_CODE CURRENCY_CODE,
            -- CK.EXCHANGE_RATE FOREIGN_CURRENCY_RATE,
            ai.exchange_rate FOREIGN_CURRENCY_RATE,
            BANK_NAME BANK_NAME,
            BANK_BRANCH_NAME BANK_BRANCH_NAME,
            LD.BANK_ACCOUNT_NAME BANK_ACCOUNT_NAME,
            NULL YTD_DAY,
            LD.LC_ID
       FROM APPS.XX_LOAN_DETAILS LD,
            AP_INVOICES_ALL AI,
            AP_INVOICE_DISTRIBUTIONS_ALL AD,
            APPS.AP_INVOICE_PAYMENTS_ALL PM,
            APPS.AP_CHECKS_ALL CK,
            APPS.XX_OU_BALSEG_V XXOU
      WHERE     LD.LOAN_ID = AD.ATTRIBUTE2(+)
            AND AI.INVOICE_ID = AD.INVOICE_ID
            AND AI.INVOICE_ID = PM.INVOICE_ID(+)
            AND PM.CHECK_ID = CK.CHECK_ID
            AND AI.CANCELLED_DATE IS NULL
            AND NVL (AD.REVERSAL_FLAG, 'N') <> 'Y'
            AND NVL (PM.REVERSAL_FLAG, 'N') <> 'Y'
            AND NVL (CK.STATUS_LOOKUP_CODE, 'XX') <> 'VOIDED'
            AND AD.ATTRIBUTE_CATEGORY = 'Loan Details'
            AND LD.ORG_ID = XXOU.ORG_ID
            AND (AI.INVOICE_TYPE_LOOKUP_CODE) IN ('STANDARD', 'MIXED')
            AND AD.LINE_TYPE_LOOKUP_CODE <> 'PREPAY'
            AND LD.LOAN_TYPE_CODE <> 'Liability on Export Bill'
            AND UPPER (AD.ATTRIBUTE7) = 'YES'
            AND AD.ATTRIBUTE3 IN ('1000',
                                  '1001',
                                  '1002',
                                  '1003',
                                  '1004',
                                  '1005',
                                  '1006',
                                  '1007',
                                  '1008')
            AND ai.doc_sequence_value NOT IN (  SELECT ai2.doc_sequence_value
                                                  FROM AP_INVOICE_DISTRIBUTIONS_ALL AD2,
                                                       AP_INVOICES_ALL AI2
                                                 WHERE     AD2.ATTRIBUTE_CATEGORY =
                                                              'Loan Details'
                                                       AND Ad2.INVOICE_ID =
                                                              AI2.INVOICE_ID
                                                       AND AI2.CANCELLED_DATE
                                                              IS NULL
                                                       AND NVL (
                                                              AD2.REVERSAL_FLAG,
                                                              'N') <> 'Y'
                                              GROUP BY ai2.doc_sequence_value,
                                                       AD2.invoice_id
                                                HAVING COUNT (
                                                          DISTINCT AD2.ATTRIBUTE2) >
                                                          1)
   GROUP BY LD.ORG_ID,
            LD.BANK_ID,
            AI.INVOICE_ID,
            LD.LOAN_ID,
            LD.LOAN_NUMBER,
            LD.BANK_BRANCH_ID,
            LD.LOAN_TYPE_CODE,
            LD.LOAN_TYPE_DESC,
            LD.OPENING_DATE,
            LD.EFFECTIVE_END_DATE,
            CK.CHECK_DATE,
            LD.LC_NUMBER,
            CK.AMOUNT,
            PM.AMOUNT,
            MAJOR_LOAN_TYPE,
            CK.CURRENCY_CODE,
            AI.EXCHANGE_RATE,
            BANK_NAME,
            BANK_BRANCH_NAME,
            LD.BANK_ACCOUNT_NAME,
            CHECK_NUMBER,
            LD.LC_ID
   UNION ALL
   --Provision Interest Part From GL
   SELECT 18 SL,
          LD.ORG_ID,
          NVL (LD.COMPANY_CODE, XXOU.COMPANY_CODE) BAL_SEG,
          LD.LOAN_ID,
          LD.LOAN_NUMBER,
          LD.BANK_ID,
          LD.BANK_BRANCH_ID,
          LD.LOAN_TYPE_CODE,
          LD.LOAN_TYPE_DESC LOAN_TYPE,
          LD.OPENING_DATE,
          LD.EFFECTIVE_END_DATE MATURITY_DATE,
          TO_NUMBER (NULL) INTEREST_RATE,
          JH.DEFAULT_EFFECTIVE_DATE,
          JH.DOC_SEQUENCE_VALUE,
          'Provision Interest',
          JL.DESCRIPTION,
          LD.LC_NUMBER,
          NVL (ENTERED_CR, 0) DR_AMOUNT,
          NVL (ENTERED_DR, 0) CR_AMOUNT,
          NVL (NVL (ACCOUNTED_CR, ENTERED_CR), 0),
          NVL (NVL (ACCOUNTED_DR, ENTERED_DR), 0),
          MAJOR_LOAN_TYPE,
          JH.CURRENCY_CODE CURRENCY_CODE,
          JH.CURRENCY_CONVERSION_RATE FOREIGN_CURRENCY_RATE,
          BANK_NAME,
          BANK_BRANCH_NAME,
          LD.BANK_ACCOUNT_NAME,
          NULL YTD_DAY,
          LD.LC_ID
     FROM APPS.XX_LOAN_DETAILS LD,
          GL_JE_HEADERS JH,
          GL_JE_LINES JL,
          APPS.XX_OU_BALSEG_V XXOU                                        ---,
    WHERE     TO_CHAR (LD.LOAN_ID) = JL.ATTRIBUTE2
          AND JH.JE_HEADER_ID = JL.JE_HEADER_ID
          AND JH.LEDGER_ID = JL.LEDGER_ID
          AND LD.ORG_ID = XXOU.ORG_ID
          AND JH.JE_CATEGORY = '1'
          AND LD.LOAN_TYPE_CODE <> 'Liability on Export Bill'
          AND JL.CONTEXT = 'Loan Details'
          AND JL.ATTRIBUTE3 IN ('1000',
                                '1001',
                                '1002',
                                '1003',
                                '1004',
                                '1005',
                                '1006',
                                '1007',
                                '1008')
          AND JH.LEDGER_ID = 2021
   UNION ALL
   --LOAN CREATED FROM CASH MODULE - CE
   SELECT 19 SL,
          LD.ORG_ID,
          NVL (LD.COMPANY_CODE, XXOU.COMPANY_CODE) BAL_SEG,
          LD.LOAN_ID,
          LD.LOAN_NUMBER,
          LD.BANK_ID,
          LD.BANK_BRANCH_ID,
          LD.LOAN_TYPE_CODE,
          LD.LOAN_TYPE_DESC LOAN_TYPE,
          LD.OPENING_DATE,
          LD.EFFECTIVE_END_DATE MATURITY_DATE,
          0 INTEREST_RATE,
          CEPTRXN.transaction_date ACCOUNTING_DATE,
          CEPTRXN.TRXN_REFERENCE_NUMBER VOUCHER,
          'Principle' CHARGE_TYPE,
          LD.DESCRIPTION,
          LD.LC_NUMBER,
          0 DR_AMOUNT,
          CEPTRXN.payment_AMOUNT CR_AMOUNT,
          0 FUNC_DR_AMOUNT,
          ABS (
             DECODE (
                LD.CURRENCY_CODE,
                'BDT', NVL (CEPTRXN.payment_AMOUNT, 0),
                (NVL (CEPTRXN.payment_AMOUNT, 0) * FOREIGN_CURRENCY_RATE)))
             FUNC_CR_AMOUNT,
          MAJOR_LOAN_TYPE,
          LD.CURRENCY_CODE,
          FOREIGN_CURRENCY_RATE,
          BANK_NAME,
          BANK_BRANCH_NAME,
          LD.BANK_ACCOUNT_NAME,
          NULL YTD_DAY,
          LD.LC_ID
     FROM APPS.XX_LOAN_DETAILS LD,
          APPS.XX_OU_BALSEG_V XXOU,
          APPS.CE_PAYMENT_TRANSACTIONS CEPTRXN
    WHERE     LD.ORG_ID = XXOU.ORG_ID
          AND CEPTRXN.ATTRIBUTE_CATEGORY = 'Loan Details'
          AND TO_CHAR (LD.LOAN_ID) = CEPTRXN.ATTRIBUTE2
          AND LD.BANK_ID = CEPTRXN.ATTRIBUTE6
          AND CEPTRXN.ATTRIBUTE3 = 1005;


GRANT SELECT ON APPS.WG_LOAN_DETAILS_V TO APPSWG;
