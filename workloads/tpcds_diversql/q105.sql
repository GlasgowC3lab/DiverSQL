WITH base AS (
    SELECT
        d.d_year,
        i.i_brand,
        cr.cr_return_amount,
        ws.ws_ext_sales_price,
        inv.inv_quantity_on_hand,
        cr.cr_net_loss,
        CASE WHEN cr.cr_net_loss > 0 THEN 1 ELSE 0 END AS loss_indicator
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN income_band ib ON hd_ref.hd_income_band_sk = ib.ib_income_band_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
                      AND ws.ws_sold_date_sk = d.d_date_sk
                      AND ws.ws_sold_time_sk = t.t_time_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
                        AND wr.wr_order_number = ws.ws_order_number
                        AND wr.wr_returned_date_sk = d.d_date_sk
                        AND wr.wr_returned_time_sk = t.t_time_sk
    WHERE d.d_year = 2002
      AND i.i_brand = 'Brand#12'
      AND wsite.web_manager = 'Peter Cassidy'
      AND ib.ib_lower_bound >= 50000
)
SELECT
    d_year,
    i_brand,
    SUM(total_return_amount) AS agg_return_amount,
    SUM(total_sales_price)   AS agg_sales_price,
    SUM(total_inventory)    AS agg_inventory,
    SUM(txn_count)          AS agg_txn_count,
    SUM(total_net_loss)     AS agg_net_loss,
    CASE WHEN SUM(total_net_loss) > 0 THEN 'Overall Loss' ELSE 'Overall Profit' END AS overall_status
FROM (
    SELECT
        d_year,
        i_brand,
        SUM(cr_return_amount)                                   AS total_return_amount,
        SUM(ws_ext_sales_price)                                 AS total_sales_price,
        SUM(inv_quantity_on_hand)                               AS total_inventory,
        COUNT(*)                                                AS txn_count,
        SUM(CASE WHEN cr_net_loss > 0 THEN cr_net_loss ELSE 0 END) AS total_net_loss
    FROM base
    WHERE loss_indicator = 0
    GROUP BY d_year, i_brand

    UNION DISTINCT

    SELECT
        d_year,
        i_brand,
        SUM(cr_return_amount)                                   AS total_return_amount,
        SUM(ws_ext_sales_price)                                 AS total_sales_price,
        SUM(inv_quantity_on_hand)                               AS total_inventory,
        COUNT(*)                                                AS txn_count,
        SUM(CASE WHEN cr_net_loss > 0 THEN cr_net_loss ELSE 0 END) AS total_net_loss
    FROM base
    WHERE loss_indicator = 1
    GROUP BY d_year, i_brand
) u
GROUP BY d_year, i_brand
ORDER BY agg_return_amount DESC
LIMIT 100
