WITH base AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        d.d_year,
        cr.cr_net_loss AS catalog_net_loss,
        sr.sr_net_loss AS store_net_loss,
        wr.wr_net_loss AS web_net_loss,
        cr.cr_return_amount,
        sr.sr_return_amt,
        wr.wr_return_amt,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        inv.inv_quantity_on_hand,
        p.p_discount_active,
        sm.sm_type,
        cd.cd_gender,
        hd.hd_buy_potential,
        ws.ws_quantity,
        ws.ws_sales_price
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    -- store returns linked by the same date and demographics
    JOIN store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
        AND sr.sr_cdemo_sk = cd.cd_demo_sk
        AND sr.sr_hdemo_sk = hd.hd_demo_sk
    -- web returns linked by the same date and demographics
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
        AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    -- web sales linked to the web return (order number & item)
    JOIN web_sales ws
        ON ws.ws_order_number = wr.wr_order_number
        AND ws.ws_item_sk = wr.wr_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
    WHERE d.d_year BETWEEN 1998 AND 2000                                   -- predicate 1
      AND ib.ib_upper_bound > 50000                                         -- predicate 2
      AND cr.cr_return_amount > 1000                                         -- predicate 3
      AND ws.ws_sales_price > 500                                            -- predicate 4
      AND sm.sm_type = 'AIR'                                                 -- predicate 5
      AND cd.cd_gender = 'M'                                                 -- predicate 6
),
agg AS (
    SELECT
        w_warehouse_name,
        d_year,
        SUM(COALESCE(catalog_net_loss, 0) + COALESCE(store_net_loss, 0) + COALESCE(web_net_loss, 0)) AS total_net_loss,
        SUM(ws_quantity) AS total_quantity,
        AVG(ws_sales_price) AS avg_sales_price
    FROM base
    GROUP BY w_warehouse_name, d_year
)
SELECT
    w_warehouse_name,
    d_year,
    total_net_loss,
    total_quantity,
    avg_sales_price,
    LAG(total_net_loss) OVER (PARTITION BY w_warehouse_name ORDER BY d_year) AS prev_year_net_loss,
    SUM(total_net_loss) OVER (PARTITION BY w_warehouse_name ORDER BY d_year ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_net_loss
FROM agg
WHERE total_quantity > 1000                                                   -- additional filter
  AND avg_sales_price > (
        SELECT AVG(ws_sales_price)
        FROM web_sales TABLESAMPLE BERNOULLI (5)                -- uncorrelated scalar subquery with sampling
        WHERE ws_sales_price IS NOT NULL
    )
ORDER BY total_net_loss DESC
