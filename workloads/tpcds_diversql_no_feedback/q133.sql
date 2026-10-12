WITH base AS (
    SELECT
        d.d_year,
        s.s_store_name,
        i.i_category,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        ss.ss_ticket_number,
        i.i_current_price,
        p.p_discount_active,
        hd.hd_vehicle_count,
        ib.ib_lower_bound,
        ca.ca_country,
        s.s_state
    FROM tpcds.date_dim d
    JOIN tpcds.store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN tpcds.item i ON ss.ss_item_sk = i.i_item_sk
    JOIN tpcds.promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN tpcds.store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN tpcds.web_returns wr ON wr.wr_item_sk = i.i_item_sk
    JOIN tpcds.inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
    JOIN tpcds.income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN tpcds.web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND ss.ss_quantity > 2
      AND i.i_current_price BETWEEN 20 AND 100
      AND p.p_discount_active = 'Y'
      AND hd.hd_vehicle_count >= 2
      AND ib.ib_lower_bound >= 50000
      AND s.s_state = 'CA'
),
agg AS (
    SELECT
        d_year,
        s_store_name,
        i_category,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss_ticket_number) AS txn_count
    FROM base
    GROUP BY ROLLUP (d_year, s_store_name, i_category)
)
SELECT
    d_year,
    s_store_name,
    i_category,
    total_sales,
    total_profit,
    txn_count,
    (
        SELECT SUM(inv2.inv_quantity_on_hand)
        FROM tpcds.inventory inv2
        JOIN tpcds.item i2 ON inv2.inv_item_sk = i2.i_item_sk
        WHERE i2.i_category = agg.i_category
    ) AS category_inventory_qty,
    DENSE_RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank_year
FROM agg
ORDER BY d_year, sales_rank_year, s_store_name
