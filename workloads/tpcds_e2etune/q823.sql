SELECT
    promo_id,
    year,
    quarter,
    buy_potential,
    sales_channel,
    net_profit,
    total_quantity,
    profit_pct,
    profit_rank
FROM (
    SELECT
        promo_id,
        year,
        quarter,
        buy_potential,
        sales_channel,
        net_profit,
        total_quantity,
        100.0 * net_profit / SUM(net_profit) OVER (PARTITION BY year, quarter) AS profit_pct,
        RANK() OVER (PARTITION BY year, quarter ORDER BY net_profit DESC) AS profit_rank
    FROM (
        SELECT
            promotion.p_promo_id AS promo_id,
            d_sales.d_year AS year,
            d_sales.d_quarter_name AS quarter,
            household_demographics.hd_buy_potential AS buy_potential,
            'store' AS sales_channel,
            SUM(store_sales.ss_net_profit) AS net_profit,
            SUM(store_sales.ss_quantity) AS total_quantity
        FROM store_sales
        JOIN date_dim d_sales ON store_sales.ss_sold_date_sk = d_sales.d_date_sk
        JOIN promotion ON store_sales.ss_promo_sk = promotion.p_promo_sk
        JOIN household_demographics ON store_sales.ss_hdemo_sk = household_demographics.hd_demo_sk
        WHERE d_sales.d_year BETWEEN 2000 AND 2002
          AND promotion.p_channel_email = 'Y'
        GROUP BY promotion.p_promo_id, d_sales.d_year, d_sales.d_quarter_name, household_demographics.hd_buy_potential

        UNION ALL

        SELECT
            promotion.p_promo_id AS promo_id,
            d_sales.d_year AS year,
            d_sales.d_quarter_name AS quarter,
            household_demographics.hd_buy_potential AS buy_potential,
            'catalog' AS sales_channel,
            SUM(catalog_sales.cs_net_profit) AS net_profit,
            SUM(catalog_sales.cs_quantity) AS total_quantity
        FROM catalog_sales
        JOIN date_dim d_sales ON catalog_sales.cs_sold_date_sk = d_sales.d_date_sk
        JOIN promotion ON catalog_sales.cs_promo_sk = promotion.p_promo_sk
        JOIN household_demographics ON catalog_sales.cs_bill_hdemo_sk = household_demographics.hd_demo_sk
        WHERE d_sales.d_year BETWEEN 2000 AND 2002
          AND promotion.p_channel_email = 'Y'
        GROUP BY promotion.p_promo_id, d_sales.d_year, d_sales.d_quarter_name, household_demographics.hd_buy_potential
    ) AS u
) AS final
WHERE net_profit > 1000
ORDER BY year, quarter, profit_rank
LIMIT 100
