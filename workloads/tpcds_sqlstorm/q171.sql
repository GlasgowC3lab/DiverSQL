WITH
store_sales_agg AS (
    SELECT
        d.d_year AS sale_year,
        d.d_moy AS sale_month,
        'store' AS channel,
        i.i_category AS category,
        SUM(ss.ss_ext_sales_price) AS sales_amount,
        SUM(ss.ss_ext_discount_amt) AS discount_amount,
        SUM(ss.ss_ext_tax) AS tax_amount,
        SUM(ss.ss_net_profit) AS net_profit,
        COUNT(*) AS order_count
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_moy, i.i_category
),
store_returns_agg AS (
    SELECT
        d.d_year AS sale_year,
        d.d_moy AS sale_month,
        'store' AS channel,
        i.i_category AS category,
        SUM(sr.sr_net_loss) AS net_loss,
        COUNT(*) AS return_count
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_moy, i.i_category
),
catalog_sales_agg AS (
    SELECT
        d.d_year AS sale_year,
        d.d_moy AS sale_month,
        'catalog' AS channel,
        i.i_category AS category,
        SUM(cs.cs_ext_sales_price) AS sales_amount,
        SUM(cs.cs_ext_discount_amt) AS discount_amount,
        SUM(cs.cs_ext_tax) AS tax_amount,
        SUM(cs.cs_net_profit) AS net_profit,
        COUNT(*) AS order_count
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_moy, i.i_category
),
catalog_returns_agg AS (
    SELECT
        d.d_year AS sale_year,
        d.d_moy AS sale_month,
        'catalog' AS channel,
        i.i_category AS category,
        SUM(cr.cr_net_loss) AS net_loss,
        COUNT(*) AS return_count
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_moy, i.i_category
),
web_sales_agg AS (
    SELECT
        d.d_year AS sale_year,
        d.d_moy AS sale_month,
        'web' AS channel,
        i.i_category AS category,
        SUM(ws.ws_ext_sales_price) AS sales_amount,
        SUM(ws.ws_ext_discount_amt) AS discount_amount,
        SUM(ws.ws_ext_tax) AS tax_amount,
        SUM(ws.ws_net_profit) AS net_profit,
        COUNT(*) AS order_count
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_moy, i.i_category
),
web_returns_agg AS (
    SELECT
        d.d_year AS sale_year,
        d.d_moy AS sale_month,
        'web' AS channel,
        i.i_category AS category,
        SUM(wr.wr_net_loss) AS net_loss,
        COUNT(*) AS return_count
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_moy, i.i_category
),
sales AS (
    SELECT
        ss.sale_year,
        ss.sale_month,
        ss.channel,
        ss.category,
        ss.sales_amount,
        ss.discount_amount,
        ss.tax_amount,
        ss.net_profit,
        ss.order_count,
        COALESCE(sr.net_loss, 0) AS net_loss,
        COALESCE(sr.return_count, 0) AS return_count
    FROM store_sales_agg ss
    LEFT JOIN store_returns_agg sr
        ON ss.sale_year = sr.sale_year
        AND ss.sale_month = sr.sale_month
        AND ss.category = sr.category
    UNION ALL
    SELECT
        cs.sale_year,
        cs.sale_month,
        cs.channel,
        cs.category,
        cs.sales_amount,
        cs.discount_amount,
        cs.tax_amount,
        cs.net_profit,
        cs.order_count,
        COALESCE(cr.net_loss, 0) AS net_loss,
        COALESCE(cr.return_count, 0) AS return_count
    FROM catalog_sales_agg cs
    LEFT JOIN catalog_returns_agg cr
        ON cs.sale_year = cr.sale_year
        AND cs.sale_month = cr.sale_month
        AND cs.category = cr.category
    UNION ALL
    SELECT
        ws.sale_year,
        ws.sale_month,
        ws.channel,
        ws.category,
        ws.sales_amount,
        ws.discount_amount,
        ws.tax_amount,
        ws.net_profit,
        ws.order_count,
        COALESCE(wr.net_loss, 0) AS net_loss,
        COALESCE(wr.return_count, 0) AS return_count
    FROM web_sales_agg ws
    LEFT JOIN web_returns_agg wr
        ON ws.sale_year = wr.sale_year
        AND ws.sale_month = wr.sale_month
        AND ws.category = wr.category
),
final_calc AS (
    SELECT
        sale_year,
        sale_month,
        channel,
        category,
        sales_amount,
        discount_amount,
        tax_amount,
        net_profit,
        net_loss,
        net_profit - net_loss AS net_gain,
        order_count,
        return_count,
        discount_amount / NULLIF(sales_amount, 0) AS discount_rate,
        ROW_NUMBER() OVER (PARTITION BY channel, sale_year, sale_month ORDER BY (net_profit - net_loss) DESC) AS rank_by_profit,
        SUM(net_profit - net_loss) OVER (PARTITION BY channel, category ORDER BY sale_year, sale_month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS three_month_rolling_gain,
        SUM(net_profit - net_loss) OVER (PARTITION BY channel, sale_year, sale_month) AS month_total_gain
    FROM sales
    WHERE sale_year = 2002
)
SELECT
    sale_year,
    sale_month,
    channel,
    category,
    net_gain,
    order_count,
    return_count,
    discount_rate,
    rank_by_profit,
    three_month_rolling_gain,
    month_total_gain,
    net_gain / NULLIF(month_total_gain, 0) AS net_gain_share
FROM final_calc
ORDER BY channel, sale_year, sale_month, rank_by_profit
LIMIT 200
