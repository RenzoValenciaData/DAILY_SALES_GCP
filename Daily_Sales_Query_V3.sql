
CREATE OR REPLACE TABLE `dev-amer-analyt-actuals-svc-7a.amer_p_la_fin_data_hub.t_fct_daily_sales_la_dev_test`  AS (
  
WITH MAPPING_LA_COMP_CODE_MARKET AS (
  SELECT  
    distinct comp_code_sap_ecc,
    UPPER(country) AS Market
  FROM `dev-amer-analyt-actuals-svc-7a.amer_p_la_fin_data_hub.v_manual_country_cluster_mapping`
),

DAILY_SALES_TABLE AS (
  SELECT
    CAST(EXTRACT(YEAR FROM pstng_date) AS STRING) AS Year
    ,CAST(EXTRACT(MONTH FROM pstng_date) AS STRING) AS Period
    ,CAST( CASE WHEN EXTRACT(MONTH FROM pstng_date) IN (1, 2, 3, 4, 5, 6) THEN 1 ELSE 2 END AS STRING) AS Half
    ,CAST(EXTRACT(QUARTER FROM pstng_date) AS STRING) AS Quarter
    ,pstng_date AS posting_date
    ,CASE comp_code
      WHEN "U013" THEN IF(LEFT(PROFIT_CTR,4) IN ("P967","P964"),"U013",IF(LEFT(PROFIT_CTR,4) IN ("P982"),"MX02_RICOLINO",null))
      ELSE comp_code
    END AS COMP_CODE
    ,LTRIM(material,"0") as SKU_Code --SKU
    ,bill_type AS billing_type
    ,rec_type AS record_type
    ,"-1" AS doc_number
    ,SUM(
      CASE COMP_CODE
        WHEN "U013" THEN IF(g_uvv003 = "LB",0.453592*g_qvv003, g_qvv003)
        ELSE g_qvv003
      END
    )/1000 AS Volume
    ,SUM(
      CASE 
        WHEN COMP_CODE = "CL02" THEN 100* zg_avv004 
        WHEN LEFT(COMP_CODE,2) = "BR" THEN IF(biczww154 = "GS",zg_avv004,0)
        ELSE zg_avv004 
      END
    ) AS Gross_Sales
    ,SUM(IF(comp_code = "CL02",100* g_avv158 , g_avv158 )) AS Trade_Incentives
    ,SUM(IF(comp_code = "CL02",100* g_avv157 , g_avv157 )) AS Consumer_Incentives
    ,SUM(
      CASE 
        WHEN LEFT(COMP_CODE,2) = "BR" THEN IF(biczww154 = "GS",g_avv150 + g_avv105 + g_avv028,IF(biczww154 = "UD", g_avv004 + zg_avv105,0))
        WHEN COMP_CODE = "CL02" THEN 100 * (g_avv028 + g_avv150 + zg_avv105)
        ELSE g_avv028 + g_avv150 + zg_avv105
      END
    ) AS SALES_ALLOW_RETURNS
    ,SUM(
      CASE 
        WHEN comp_code = "CL02" THEN 100* g_avv159
        WHEN COMP_CODE = "U013" THEN IF(BICZWW154 = "NP",biczvv160,0) + g_avv159
        ELSE g_avv159
      END 
    ) AS NPD
  FROM `prd-amer-analyt-datal-svc-88.amer_h_sapbw_rtr.t_copa_line_items_amer` 

  WHERE FISCPER >= "2023001" 
    AND COMP_CODE IN ("AR02", "BO03","CL02", "CO05", "CR02", "DO03", "EC02", "GT02", "HN02", "MX02", "NI02", "PA02", "PE02", "PR04", "SV02", "U013", "UY02")
    AND IF(COMP_CODE IN ("EC02","PR04","PA02","SV02","U013"), CURRENCY = "USD", CURRENCY != "USD")
    AND IF(COMP_CODE = "U013",LEFT(PROFIT_CTR,4) IN ("P967","P964","P982"),1=1) 
    AND (BICZWW153 IS NULL OR BICZWW153 = "ES") 
  GROUP BY 1,2,3,4,5,6,7,8,9
  HAVING (Volume != 0 OR Gross_Sales !=0 OR Trade_Incentives !=0 OR Consumer_Incentives !=0 OR SALES_ALLOW_RETURNS !=0 OR Trade_Incentives != 0 OR NPD !=0)
),

DAILY_SALES_BRAZIL_TABLE_BEFORE_2024007 AS (
  SELECT
    CAST(EXTRACT(YEAR FROM pstng_date) AS STRING) AS Year
    ,CAST(EXTRACT(MONTH FROM pstng_date) AS STRING) AS Period
    ,CAST(CASE WHEN EXTRACT(MONTH FROM pstng_date) IN (1, 2, 3, 4, 5, 6) THEN 1 ELSE 2 END AS STRING) AS Half
    ,CAST(EXTRACT(QUARTER FROM pstng_date) AS STRING) AS Quarter
    ,pstng_date AS posting_date
    ,comp_code
    ,LTRIM(material,"0") as SKU_Code --SKU
    ,bill_type AS billing_type
    ,rec_type AS record_type
    ,"-1" AS doc_number
    ,SUM(g_qvv003)/1000 AS Volume
    ,SUM(
      CASE
        WHEN LEFT(COMP_CODE,2) = "BR" THEN IF(biczww154 = "GS",zg_avv004,0)
        ELSE zg_avv004 
      END
    ) AS Gross_Sales
    ,SUM(g_avv158) AS Trade_Incentives
    ,SUM(g_avv157) AS Consumer_Incentives
    ,SUM(
      CASE 
        WHEN LEFT(COMP_CODE,2) = "BR" THEN IF(biczww154 = "GS",g_avv150 + g_avv105 + g_avv028,IF(biczww154 = "UD", g_avv004 + zg_avv105,0))
      END
    ) AS SALES_ALLOW_RETURNS
    ,SUM(g_avv159) AS NPD
  FROM `prd-amer-analyt-datal-svc-88.amer_h_sapbw_rtr.t_copa_line_items_amer` 

  WHERE FISCPER BETWEEN "2023001" AND "2024006" 
    AND COMP_CODE IN ("BR02", "BR04")
    AND IF(COMP_CODE IN ("EC02","PR04","PA02","SV02","U013"), CURRENCY = "USD", CURRENCY != "USD")
    AND (BICZWW153 IS NULL OR BICZWW153 = "ES") 
  GROUP BY 1,2,3,4,5,6,7,8,9
  HAVING (Volume != 0 OR Gross_Sales !=0 OR Trade_Incentives !=0 OR Consumer_Incentives !=0 OR SALES_ALLOW_RETURNS !=0 OR Trade_Incentives != 0 OR NPD !=0)
),

DAILY_SALES_BRAZIL_TABLE_AFTER_2024007 AS (
  SELECT
    CAST(EXTRACT(YEAR FROM pstng_date) AS STRING) AS Year
    ,CAST(EXTRACT(MONTH FROM pstng_date) AS STRING) AS Period
    ,CAST( CASE WHEN EXTRACT(MONTH FROM pstng_date) IN (1, 2, 3, 4, 5, 6) THEN 1 ELSE 2 END AS STRING) AS Half
    ,CAST(EXTRACT(QUARTER FROM pstng_date) AS STRING) AS Quarter
    ,pstng_date AS posting_date
    ,comp_code
    ,LTRIM(material,"0") as SKU_Code --SKU
    ,"-1" AS billing_type
    ,"-1" AS record_type
    ,me_co_doc AS doc_number
    ,SUM(g_qvv003)/1000 AS Volume
    ,SUM(
      CASE
        WHEN LEFT(COMP_CODE,2) = "BR" THEN IF(biczww154 = "GS",zg_avv004,0)
        ELSE zg_avv004 
      END
    ) AS Gross_Sales
    ,SUM(g_avv158) AS Trade_Incentives
    ,SUM(g_avv157) AS Consumer_Incentives
    ,SUM(
      CASE 
        WHEN LEFT(COMP_CODE,2) = "BR" THEN IF(biczww154 = "GS",g_avv150 + g_avv105 + g_avv028,IF(biczww154 = "UD", g_avv004 + zg_avv105,0))
      END
    ) AS SALES_ALLOW_RETURNS
    ,SUM(g_avv159) AS NPD
  FROM `prd-amer-analyt-datal-svc-88.amer_h_sapbw_rtr.t_copa_line_items_amer` 

  WHERE FISCPER >= "2024007" 
    AND COMP_CODE IN ("BR02", "BR04")
    AND IF(COMP_CODE IN ("EC02","PR04","PA02","SV02","U013"), CURRENCY = "USD", CURRENCY != "USD")
    AND (BICZWW153 IS NULL OR BICZWW153 = "ES") 
  GROUP BY 1,2,3,4,5,6,7,8,9,10
  HAVING (Volume != 0 OR Gross_Sales !=0 OR Trade_Incentives !=0 OR Consumer_Incentives !=0 OR SALES_ALLOW_RETURNS !=0 OR Trade_Incentives != 0 OR NPD !=0)
),

UNION_DAILY_SALES AS (
  SELECT * FROM DAILY_SALES_TABLE
  UNION ALL
  SELECT * FROM DAILY_SALES_BRAZIL_TABLE_AFTER_2024007
  UNION ALL
  SELECT * FROM DAILY_SALES_BRAZIL_TABLE_BEFORE_2024007
)


SELECT 
  Year
  ,Period
  ,Half
  ,Quarter
  ,posting_date
  ,IFNULL(market_mapping.Market,"MEXICO RICOLINO") AS Market
  ,sku_code
  ,billing_type 
  ,record_type
  ,doc_number
  ,SUM(Volume) AS Sell_In_Tons
  ,SUM(Gross_Sales) AS Sell_In_Gross_Sales
  ,SUM(Gross_Sales + Trade_Incentives + Consumer_Incentives + Sales_Allow_Returns + NPD) AS Sell_In_NR
FROM UNION_DAILY_SALES daily_data
LEFT JOIN MAPPING_LA_COMP_CODE_MARKET Market_Mapping ON daily_data.Comp_code = market_mapping.comp_code_sap_ecc
GROUP BY 1,2,3,4,5,6,7,8,9,10
HAVING (Sell_In_Tons != 0 OR Sell_In_Gross_Sales != 0 OR Sell_In_NR != 0)
)