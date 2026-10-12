WITH cs_promo AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_promo_sk,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_bill_cdemo_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_ext_discount_amt
    FROM catalog_sales cs
), promo_filtered AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_id,
        p.p_promo_name,
        p.p_channel_email
    FROM promotion p
    WHERE regexp_like(p.p_promo_name, 'Discount')
      AND p.p_channel_email LIKE '%@%'
)
SELECT
    COALESCE(pf.p_promo_id, 'UNKNOWN') AS promo_id,
    COALESCE(CONCAT(cd.cd_gender, '-', cd.cd_marital_status), 'UNKNOWN') AS demographic_key,
    COALESCE(td.t_hour, -1) AS hour_of_day,
    SUM(COALESCE(csp.cs_ext_sales_price, 0)) AS total_sales_amount,
    SUM(COALESCE(csp.cs_net_paid, 0)) AS total_net_paid,
    SUM(COALESCE(csp.cs_net_profit, 0)) AS total_net_profit,
    COUNT(COALESCE(csp.cs_quantity, 0)) AS total_quantity,
    CASE
        WHEN SUM(COALESCE(csp.cs_net_profit, 0)) > 0 THEN 'POSITIVE'
        ELSE 'NON_POSITIVE'
    END AS profit_flag
FROM cs_promo csp
FULL OUTER JOIN promo_filtered pf
    ON csp.cs_promo_sk = pf.p_promo_sk
LEFT JOIN customer_demographics cd
    ON csp.cs_bill_cdemo_sk = cd.cd_demo_sk
LEFT JOIN time_dim td
    ON csp.cs_sold_time_sk = td.t_time_sk
WHERE EXISTS (
    SELECT 1
    FROM store_sales ss
    WHERE ss.ss_promo_sk = pf.p_promo_sk
      AND ss.ss_sold_date_sk = csp.cs_sold_date_sk
)
GROUP BY
    COALESCE(pf.p_promo_id, 'UNKNOWN'),
    COALESCE(CONCAT(cd.cd_gender, '-', cd.cd_marital_status), 'UNKNOWN'),
    COALESCE(td.t_hour, -1)
ORDER BY total_net_profit DESC
LIMIT 100
