WITH sales_agg AS (
    SELECT
        ss_sold_date_sk,
        ss_sold_time_sk,
        ss_item_sk,
        ss_customer_sk,
        ss_cdemo_sk,
        ss_hdemo_sk,
        ss_addr_sk,
        ss_store_sk,
        ss_promo_sk,
        ss_ticket_number,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_net_paid) AS total_net_paid,
        MAP(
            ARRAY['net_paid','sales_price'],
            ARRAY[SUM(ss_net_paid), SUM(ss_ext_sales_price)]
        ) AS sales_metrics
    FROM store_sales
    GROUP BY
        ss_sold_date_sk,
        ss_sold_time_sk,
        ss_item_sk,
        ss_customer_sk,
        ss_cdemo_sk,
        ss_hdemo_sk,
        ss_addr_sk,
        ss_store_sk,
        ss_promo_sk,
        ss_ticket_number
),
joined_data AS (
    SELECT
        ca1.ca_state,
        cd1.cd_gender,
        hd1.hd_buy_potential,
        i_item.i_brand,
        p.p_promo_name,
        ib.ib_lower_bound,
        metric_name,
        metric_value,
        sa.total_quantity,
        sa.total_sales,
        sa.total_net_paid,
        COALESCE(r.sr_return_amt, 0) AS return_amt
    FROM sales_agg sa
    JOIN customer_address ca1 ON sa.ss_addr_sk = ca1.ca_address_sk
    JOIN customer_demographics cd1 ON sa.ss_cdemo_sk = cd1.cd_demo_sk
    JOIN household_demographics hd1 ON sa.ss_hdemo_sk = hd1.hd_demo_sk
    JOIN item i_item ON sa.ss_item_sk = i_item.i_item_sk
    JOIN promotion p ON sa.ss_promo_sk = p.p_promo_sk
    JOIN income_band ib ON hd1.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store_returns r ON r.sr_ticket_number = sa.ss_ticket_number
    JOIN customer_demographics cd2 ON r.sr_cdemo_sk = cd2.cd_demo_sk
    JOIN household_demographics hd2 ON r.sr_hdemo_sk = hd2.hd_demo_sk
    JOIN customer_address ca2 ON r.sr_addr_sk = ca2.ca_address_sk
    JOIN item i_promo ON p.p_item_sk = i_promo.i_item_sk
    CROSS JOIN UNNEST(sa.sales_metrics) AS t(metric_name, metric_value)
),
final_agg AS (
    SELECT
        ca_state,
        cd_gender,
        hd_buy_potential,
        i_brand,
        p_promo_name,
        ib_lower_bound,
        metric_name,
        SUM(metric_value) AS metric_total,
        SUM(total_quantity) AS total_quantity,
        SUM(total_sales) AS total_sales,
        SUM(total_net_paid) AS total_net_paid,
        SUM(return_amt) AS total_return_amt
    FROM joined_data
    GROUP BY CUBE (
        ca_state,
        cd_gender,
        hd_buy_potential,
        i_brand,
        p_promo_name,
        ib_lower_bound,
        metric_name
    )
)
SELECT *
FROM final_agg
ORDER BY metric_total DESC
LIMIT 100
