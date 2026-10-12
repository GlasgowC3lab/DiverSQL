WITH unified_sales AS (
    SELECT
        cs.cs_sold_date_sk AS sold_date_sk,
        cs.cs_sold_time_sk AS sold_time_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_bill_cdemo_sk AS cdemo_sk,
        cs.cs_bill_addr_sk AS address_sk,
        cs.cs_promo_sk AS promo_sk,
        cs.cs_net_paid_inc_tax AS net_paid_inc_tax,
        cs.cs_ext_discount_amt AS discount_amt,
        cs.cs_quantity AS quantity,
        cs.cs_net_profit AS net_profit,
        'catalog' AS sales_channel
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk BETWEEN 2450815 AND 2450825
      AND cs.cs_ext_discount_amt > 0
      AND cs.cs_quantity >= 20
    UNION ALL
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_cdemo_sk,
        ss.ss_addr_sk,
        ss.ss_promo_sk,
        ss.ss_net_paid_inc_tax,
        ss.ss_ext_discount_amt,
        ss.ss_quantity,
        ss.ss_net_profit,
        'store' AS sales_channel
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk BETWEEN 2450815 AND 2450825
      AND ss.ss_ext_discount_amt > 0
      AND ss.ss_quantity >= 20
)

SELECT
    i.i_brand,
    u.sold_date_sk,
    u.sales_channel,
    p.p_channel_catalog,
    COUNT(*) AS txn_cnt,
    SUM(u.net_paid_inc_tax) AS total_net_paid,
    SUM(u.discount_amt) AS total_discount,
    SUM(u.net_profit) AS total_net_profit,
    AVG(u.net_paid_inc_tax) AS avg_net_paid,
    RANK() OVER (PARTITION BY i.i_brand ORDER BY SUM(u.net_profit) DESC) AS profit_rank
FROM unified_sales u
JOIN item i ON u.item_sk = i.i_item_sk
JOIN promotion p ON u.promo_sk = p.p_promo_sk
JOIN time_dim t ON u.sold_time_sk = t.t_time_sk
JOIN customer_demographics cd ON u.cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca ON u.address_sk = ca.ca_address_sk
WHERE p.p_discount_active = 'Y'
  AND ca.ca_country = 'United States'
  AND t.t_hour BETWEEN 9 AND 21
GROUP BY
    i.i_brand,
    u.sold_date_sk,
    u.sales_channel,
    p.p_channel_catalog
HAVING SUM(u.net_profit) > 0
ORDER BY total_net_profit DESC
LIMIT 50
