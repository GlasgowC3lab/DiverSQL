WITH sales_base AS (
    SELECT
        cs.cs_sold_date_sk AS sold_date_sk,
        cs.cs_sold_time_sk AS sold_time_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_call_center_sk AS call_center_sk,
        cs.cs_warehouse_sk AS warehouse_sk,
        cs.cs_promo_sk AS promo_sk,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        cs.cs_quantity AS quantity,
        'catalog' AS sales_channel
    FROM catalog_sales cs
    UNION ALL
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        CAST(NULL AS INTEGER) AS call_center_sk,
        CAST(NULL AS INTEGER) AS warehouse_sk,
        ss.ss_promo_sk,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_quantity,
        'store' AS sales_channel
    FROM store_sales ss
    UNION ALL
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        CAST(NULL AS INTEGER) AS call_center_sk,
        ws.ws_warehouse_sk,
        ws.ws_promo_sk,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_quantity,
        'web' AS sales_channel
    FROM web_sales ws
),
returns_raw AS (
    SELECT
        cr.cr_returned_date_sk AS return_date_sk,
        cr.cr_item_sk AS item_sk,
        cr.cr_return_quantity AS return_quantity,
        cr.cr_net_loss AS net_loss,
        'catalog' AS return_channel
    FROM catalog_returns cr
    UNION ALL
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_item_sk,
        sr.sr_return_quantity,
        sr.sr_net_loss,
        'store' AS return_channel
    FROM store_returns sr
    UNION ALL
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_item_sk,
        wr.wr_return_quantity,
        wr.wr_net_loss,
        'web' AS return_channel
    FROM web_returns wr
),
returns_agg AS (
    SELECT
        return_date_sk,
        item_sk,
        return_channel,
        SUM(return_quantity) AS total_return_qty,
        SUM(net_loss) AS total_net_loss
    FROM returns_raw
    GROUP BY return_date_sk, item_sk, return_channel
),
sales_with_returns AS (
    SELECT
        sb.*,
        COALESCE(ra.total_return_qty, 0) AS return_quantity,
        COALESCE(ra.total_net_loss, 0) AS return_net_loss
    FROM sales_base sb
    LEFT JOIN returns_agg ra
        ON sb.sold_date_sk = ra.return_date_sk
        AND sb.item_sk = ra.item_sk
        AND sb.sales_channel = ra.return_channel
),
sales_enriched AS (
    SELECT
        swr.*,
        d.d_year,
        d.d_moy AS month,
        i.i_item_id,
        i.i_product_name,
        i.i_brand,
        i.i_category,
        c.c_first_name,
        c.c_last_name,
        c.c_customer_id,
        COALESCE(cc.cc_name, 'N/A') AS call_center_name,
        COALESCE(w.w_warehouse_name, 'N/A') AS warehouse_name,
        COALESCE(p.p_discount_active, 'N') AS promo_active_flag,
        CASE
            WHEN (swr.net_paid - swr.return_net_loss) < 0 THEN 0
            ELSE (swr.net_paid - swr.return_net_loss)
        END AS net_sales,
        (swr.net_profit / NULLIF(swr.net_paid, 0)) * 100 AS profit_margin_pct,
        CONCAT(c.c_first_name, ' ', c.c_last_name, ' (', c.c_customer_id, ')') AS customer_full_name
    FROM sales_with_returns swr
    LEFT JOIN date_dim d ON swr.sold_date_sk = d.d_date_sk
    LEFT JOIN item i ON swr.item_sk = i.i_item_sk
    LEFT JOIN customer c ON swr.customer_sk = c.c_customer_sk
    LEFT JOIN call_center cc ON swr.call_center_sk = cc.cc_call_center_sk
    LEFT JOIN warehouse w ON swr.warehouse_sk = w.w_warehouse_sk
    LEFT JOIN promotion p ON swr.promo_sk = p.p_promo_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
),
customer_rankings AS (
    SELECT
        customer_sk,
        customer_full_name,
        SUM(net_sales) AS total_spent,
        RANK() OVER (ORDER BY SUM(net_sales) DESC) AS spend_rank
    FROM sales_enriched
    GROUP BY customer_sk, customer_full_name
    HAVING SUM(net_sales) > 5000
),
customer_top_items AS (
    SELECT
        customer_sk,
        item_sk,
        net_sales,
        ROW_NUMBER() OVER (PARTITION BY customer_sk ORDER BY net_sales DESC) AS rn
    FROM sales_enriched
),
monthly_metrics AS (
    SELECT
        d_year,
        month,
        sales_channel,
        warehouse_name,
        call_center_name,
        SUM(net_sales) AS month_sales,
        SUM(net_profit) AS month_profit,
        COUNT(DISTINCT customer_sk) AS distinct_customers,
        AVG(profit_margin_pct) AS avg_profit_margin_pct,
        LAG(SUM(net_sales)) OVER (PARTITION BY sales_channel, warehouse_name ORDER BY d_year, month) AS prev_month_sales,
        CASE
            WHEN LAG(SUM(net_sales)) OVER (PARTITION BY sales_channel, warehouse_name ORDER BY d_year, month) IS NULL THEN NULL
            ELSE (SUM(net_sales) - LAG(SUM(net_sales)) OVER (PARTITION BY sales_channel, warehouse_name ORDER BY d_year, month))
                 / NULLIF(LAG(SUM(net_sales)) OVER (PARTITION BY sales_channel, warehouse_name ORDER BY d_year, month), 0)
        END AS month_over_month_growth
    FROM sales_enriched
    GROUP BY d_year, month, sales_channel, warehouse_name, call_center_name
),
monthly_item_sales AS (
    SELECT
        d_year,
        month,
        sales_channel,
        warehouse_name,
        call_center_name,
        item_sk,
        i_product_name,
        SUM(net_sales) AS item_month_sales
    FROM sales_enriched
    GROUP BY d_year, month, sales_channel, warehouse_name, call_center_name, item_sk, i_product_name
),
top_item_per_month AS (
    SELECT
        d_year,
        month,
        sales_channel,
        warehouse_name,
        call_center_name,
        item_sk,
        i_product_name,
        item_month_sales,
        ROW_NUMBER() OVER (PARTITION BY d_year, month, sales_channel, warehouse_name, call_center_name ORDER BY item_month_sales DESC) AS rn
    FROM monthly_item_sales
),
with_prev_month_item_avg AS (
    SELECT
        se.*,
        (
            SELECT AVG(se2.net_profit)
            FROM sales_enriched se2
            WHERE se2.item_sk = se.item_sk
              AND se2.d_year = se.d_year
              AND se2.month = se.month - 1
        ) AS prev_month_item_avg_profit
    FROM sales_enriched se
)
SELECT
    mm.d_year,
    mm.month,
    mm.sales_channel,
    mm.warehouse_name,
    mm.call_center_name,
    mm.month_sales,
    mm.month_profit,
    mm.distinct_customers,
    mm.avg_profit_margin_pct,
    mm.prev_month_sales,
    mm.month_over_month_growth,
    tip.item_sk AS top_item_sk,
    tip.i_product_name AS top_item_name,
    tip.item_month_sales AS top_item_sales,
    cr.customer_full_name,
    cr.total_spent,
    cr.spend_rank,
    wpi.prev_month_item_avg_profit
FROM monthly_metrics mm
LEFT JOIN top_item_per_month tip
    ON mm.d_year = tip.d_year
   AND mm.month = tip.month
   AND mm.sales_channel = tip.sales_channel
   AND mm.warehouse_name = tip.warehouse_name
   AND mm.call_center_name = tip.call_center_name
   AND tip.rn = 1
LEFT JOIN customer_rankings cr
    ON mm.warehouse_name = CAST(cr.customer_sk AS VARCHAR)
LEFT JOIN with_prev_month_item_avg wpi
    ON mm.d_year = wpi.d_year
   AND mm.month = wpi.month
   AND mm.sales_channel = wpi.sales_channel
   AND mm.warehouse_name = wpi.warehouse_name
   AND mm.call_center_name = wpi.call_center_name
WHERE mm.month_sales > 0
ORDER BY mm.d_year DESC, mm.month DESC, mm.sales_channel
