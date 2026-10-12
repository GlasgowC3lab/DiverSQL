WITH sales_union AS (
    SELECT cs_sold_date_sk AS sales_date_sk,
           cs_item_sk AS item_sk,
           'catalog' AS channel_type,
           cs_quantity AS quantity,
           cs_ext_sales_price AS ext_sales_price,
           cs_ext_discount_amt AS ext_discount_amt,
           cs_net_paid AS net_paid,
           cs_net_profit AS net_profit,
           cs_bill_cdemo_sk AS demo_sk
    FROM catalog_sales
    UNION ALL
    SELECT ss_sold_date_sk,
           ss_item_sk,
           'store',
           ss_quantity,
           ss_ext_sales_price,
           ss_ext_discount_amt,
           ss_net_paid,
           ss_net_profit,
           ss_cdemo_sk
    FROM store_sales
    UNION ALL
    SELECT ws_sold_date_sk,
           ws_item_sk,
           'web',
           ws_quantity,
           ws_ext_sales_price,
           ws_ext_discount_amt,
           ws_net_paid,
           ws_net_profit,
           ws_bill_cdemo_sk
    FROM web_sales
),
returns_union AS (
    SELECT cr_returned_date_sk AS return_date_sk,
           cr_item_sk AS item_sk,
           'catalog' AS channel_type,
           cr_return_quantity AS quantity,
           cr_return_amount AS return_amount,
           cr_return_tax AS return_tax,
           cr_net_loss AS net_loss,
           cr_refunded_cdemo_sk AS demo_sk
    FROM catalog_returns
    UNION ALL
    SELECT sr_returned_date_sk,
           sr_item_sk,
           'store',
           sr_return_quantity,
           sr_return_amt,
           sr_return_tax,
           sr_net_loss,
           sr_cdemo_sk
    FROM store_returns
    UNION ALL
    SELECT wr_returned_date_sk,
           wr_item_sk,
           'web',
           wr_return_quantity,
           wr_return_amt,
           wr_return_tax,
           wr_net_loss,
           wr_refunded_cdemo_sk
    FROM web_returns
),
sales_by_month AS (
    SELECT d.d_year,
           d.d_moy AS month,
           su.channel_type,
           i.i_category,
           i.i_brand,
           sum(su.quantity) AS total_quantity,
           sum(su.ext_sales_price) AS total_sales,
           sum(su.ext_discount_amt) AS total_discount,
           sum(su.net_paid) AS total_net_paid,
           sum(su.net_profit) AS total_net_profit,
           approx_percentile(CAST(su.ext_discount_amt AS double) / nullif(su.quantity, 0), 0.5) AS median_discount_per_unit,
           count(DISTINCT su.demo_sk) AS distinct_demo_count
    FROM sales_union su
    JOIN date_dim d ON su.sales_date_sk = d.d_date_sk
    JOIN item i ON su.item_sk = i.i_item_sk
    LEFT JOIN customer_demographics cd ON su.demo_sk = cd.cd_demo_sk
    GROUP BY d.d_year, d.d_moy, su.channel_type, i.i_category, i.i_brand
),
returns_by_month AS (
    SELECT d.d_year,
           d.d_moy AS month,
           ru.channel_type,
           i.i_category,
           i.i_brand,
           sum(ru.quantity) AS total_return_quantity,
           sum(ru.return_amount) AS total_return_amount,
           sum(ru.net_loss) AS total_return_net_loss,
           count(DISTINCT ru.demo_sk) AS distinct_return_demo_count
    FROM returns_union ru
    JOIN date_dim d ON ru.return_date_sk = d.d_date_sk
    JOIN item i ON ru.item_sk = i.i_item_sk
    LEFT JOIN customer_demographics cd ON ru.demo_sk = cd.cd_demo_sk
    GROUP BY d.d_year, d.d_moy, ru.channel_type, i.i_category, i.i_brand
),
combined AS (
    SELECT
        s.d_year,
        s.month,
        s.channel_type,
        s.i_category,
        s.i_brand,
        s.total_quantity,
        s.total_sales,
        s.total_discount,
        s.total_net_paid,
        s.total_net_profit,
        s.median_discount_per_unit,
        s.distinct_demo_count,
        COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(r.total_return_amount, 0) AS total_return_amount,
        COALESCE(r.total_return_net_loss, 0) AS total_return_net_loss,
        COALESCE(r.distinct_return_demo_count, 0) AS distinct_return_demo_count,
        (s.total_net_profit - COALESCE(r.total_return_net_loss, 0)) AS net_profit_after_returns,
        (s.total_sales - COALESCE(r.total_return_amount, 0)) AS net_sales_after_returns,
        (s.total_quantity - COALESCE(r.total_return_quantity, 0)) AS net_quantity_after_returns
    FROM sales_by_month s
    LEFT JOIN returns_by_month r
        ON s.d_year = r.d_year
        AND s.month = r.month
        AND s.channel_type = r.channel_type
        AND s.i_category = r.i_category
        AND s.i_brand = r.i_brand
),
ranked AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY d_year, month, channel_type ORDER BY net_profit_after_returns DESC) AS profit_rank
    FROM combined
)
SELECT
    d_year,
    month,
    channel_type,
    i_category,
    i_brand,
    total_quantity,
    total_sales,
    total_discount,
    total_net_paid,
    total_net_profit,
    median_discount_per_unit,
    distinct_demo_count,
    total_return_quantity,
    total_return_amount,
    total_return_net_loss,
    distinct_return_demo_count,
    net_profit_after_returns,
    net_sales_after_returns,
    net_quantity_after_returns,
    profit_rank
FROM ranked
WHERE profit_rank <= 10
ORDER BY d_year, month, channel_type, profit_rank
