WITH unified_sales AS (
    SELECT
        'store' AS channel,
        ss.ss_sold_date_sk AS sold_date_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_customer_sk AS customer_sk,
        ss.ss_quantity AS quantity,
        ss.ss_net_profit AS net_profit,
        ss.ss_net_paid AS net_paid,
        ss.ss_ext_discount_amt AS discount_amt,
        ss.ss_promo_sk AS promo_sk
    FROM store_sales ss
    UNION ALL
    SELECT
        'catalog' AS channel,
        cs.cs_sold_date_sk AS sold_date_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_quantity AS quantity,
        cs.cs_net_profit AS net_profit,
        cs.cs_net_paid AS net_paid,
        cs.cs_ext_discount_amt AS discount_amt,
        cs.cs_promo_sk AS promo_sk
    FROM catalog_sales cs
    UNION ALL
    SELECT
        'web' AS channel,
        ws.ws_sold_date_sk AS sold_date_sk,
        ws.ws_item_sk AS item_sk,
        ws.ws_bill_customer_sk AS customer_sk,
        ws.ws_quantity AS quantity,
        ws.ws_net_profit AS net_profit,
        ws.ws_net_paid AS net_paid,
        ws.ws_ext_discount_amt AS discount_amt,
        ws.ws_promo_sk AS promo_sk
    FROM web_sales ws
), sales_with_date AS (
    SELECT
        us.*,
        d.d_date,
        d.d_year,
        d.d_month_seq
    FROM unified_sales us
    LEFT JOIN date_dim d ON us.sold_date_sk = d.d_date_sk
), sales_enriched AS (
    SELECT
        swd.channel,
        swd.sold_date_sk,
        swd.d_date,
        swd.d_year,
        swd.d_month_seq,
        swd.item_sk,
        i.i_category,
        i.i_class,
        i.i_brand,
        swd.customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(c.c_preferred_cust_flag, 'N') AS preferred_flag,
        swd.quantity,
        swd.net_profit,
        swd.net_paid,
        swd.discount_amt,
        swd.promo_sk,
        p.p_promo_name,
        CASE WHEN swd.net_paid = 0 THEN NULL ELSE swd.net_profit / swd.net_paid END AS profit_margin,
        (SELECT COALESCE(SUM(sr.sr_return_amt), 0)
         FROM store_returns sr
         WHERE sr.sr_item_sk = swd.item_sk
           AND sr.sr_returned_date_sk = swd.sold_date_sk) AS total_store_return_amt,
        (SELECT COALESCE(SUM(cr.cr_return_amount), 0)
         FROM catalog_returns cr
         WHERE cr.cr_item_sk = swd.item_sk
           AND cr.cr_returned_date_sk = swd.sold_date_sk) AS total_catalog_return_amt,
        (SELECT COALESCE(SUM(wr.wr_return_amt), 0)
         FROM web_returns wr
         WHERE wr.wr_item_sk = swd.item_sk
           AND wr.wr_returned_date_sk = swd.sold_date_sk) AS total_web_return_amt
    FROM sales_with_date swd
    LEFT JOIN item i ON swd.item_sk = i.i_item_sk
    LEFT JOIN customer c ON swd.customer_sk = c.c_customer_sk
    LEFT JOIN promotion p ON swd.promo_sk = p.p_promo_sk
), ranked_sales AS (
    SELECT
        se.*,
        ROW_NUMBER() OVER (PARTITION BY se.d_year, se.d_month_seq ORDER BY se.net_profit DESC) AS profit_rank,
        SUM(se.net_profit) OVER (PARTITION BY se.customer_sk ORDER BY se.sold_date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_customer_profit,
        LAG(se.net_profit, 1) OVER (PARTITION BY se.customer_sk ORDER BY se.sold_date_sk) AS prev_profit
    FROM sales_enriched se
), final_agg AS (
    SELECT
        rs.channel,
        rs.d_year,
        rs.d_month_seq,
        COUNT(DISTINCT rs.customer_sk) AS distinct_customers,
        SUM(rs.quantity) AS total_quantity,
        SUM(rs.net_profit) AS total_profit,
        AVG(rs.profit_margin) AS avg_profit_margin,
        SUM(rs.total_store_return_amt) AS total_store_returns,
        SUM(rs.total_catalog_return_amt) AS total_catalog_returns,
        SUM(rs.total_web_return_amt) AS total_web_returns,
        MAX(rs.cumulative_customer_profit) AS max_cumulative_customer_profit,
        COUNT(CASE WHEN rs.preferred_flag = 'Y' THEN 1 END) AS preferred_customers,
        CONCAT('Top ', CAST(MIN(rs.profit_rank) AS VARCHAR), ' Profit Channels for ', CAST(rs.d_year AS VARCHAR), '-', LPAD(CAST(mod(rs.d_month_seq, 12) + 1 AS VARCHAR), 2, '0')) AS report_title
    FROM ranked_sales rs
    WHERE rs.profit_rank <= 5
    GROUP BY rs.channel, rs.d_year, rs.d_month_seq
)
SELECT *
FROM final_agg
ORDER BY d_year DESC, d_month_seq DESC, total_profit DESC
