WITH sales_data AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        'catalog' AS channel,
        cs.cs_ext_sales_price AS sales_amount,
        cs.cs_net_profit AS profit,
        cr.cr_return_amt_inc_tax AS return_amount,
        cs.cs_quantity AS sales_qty,
        cs.cs_ext_discount_amt / NULLIF(cs.cs_quantity, 0) AS discount
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number AND cs.cs_item_sk = cr.cr_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
      AND p.p_discount_active = 'Y'
    UNION ALL
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        'store' AS channel,
        ss.ss_ext_sales_price AS sales_amount,
        ss.ss_net_profit AS profit,
        sr.sr_return_amt_inc_tax AS return_amount,
        ss.ss_quantity AS sales_qty,
        ss.ss_ext_discount_amt / NULLIF(ss.ss_quantity, 0) AS discount
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number AND ss.ss_item_sk = sr.sr_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
      AND p.p_discount_active = 'Y'
    UNION ALL
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        'web' AS channel,
        ws.ws_ext_sales_price AS sales_amount,
        ws.ws_net_profit AS profit,
        wr.wr_return_amt_inc_tax AS return_amount,
        ws.ws_quantity AS sales_qty,
        ws.ws_ext_discount_amt / NULLIF(ws.ws_quantity, 0) AS discount
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number AND ws.ws_item_sk = wr.wr_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
      AND p.p_discount_active = 'Y'
), aggregated AS (
    SELECT
        d_year,
        d_month_seq,
        i_category,
        channel,
        SUM(sales_amount) AS total_sales,
        SUM(profit) AS total_profit,
        SUM(COALESCE(return_amount, 0)) AS total_returns,
        SUM(sales_qty) AS total_quantity,
        AVG(discount) AS avg_discount
    FROM sales_data
    GROUP BY d_year, d_month_seq, i_category, channel
)
SELECT
    d_year,
    d_month_seq,
    i_category,
    channel,
    total_sales,
    total_profit,
    total_returns,
    total_quantity,
    avg_discount,
    RANK() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_profit DESC) AS profit_rank
FROM aggregated
ORDER BY d_year, d_month_seq, profit_rank
