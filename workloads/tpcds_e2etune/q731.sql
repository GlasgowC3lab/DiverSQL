WITH
store_sales_agg AS (
    SELECT
        cd.cd_gender AS gender,
        ca.ca_state AS state,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_sales_count,
        SUM(ss.ss_net_profit) AS total_store_profit
    FROM store_sales ss
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2451915 AND 2451925
    GROUP BY cd.cd_gender, ca.ca_state
),
store_returns_agg AS (
    SELECT
        cd.cd_gender AS gender,
        ca.ca_state AS state,
        COUNT(DISTINCT sr.sr_ticket_number) AS store_return_count,
        SUM(sr.sr_net_loss) AS total_store_return_loss,
        SUM(sr.sr_return_quantity) AS total_store_return_qty
    FROM store_returns sr
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2451915 AND 2451925
    GROUP BY cd.cd_gender, ca.ca_state
),
catalog_sales_agg AS (
    SELECT
        cd.cd_gender AS gender,
        ca.ca_state AS state,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_sales_count,
        SUM(cs.cs_net_profit) AS total_catalog_profit
    FROM catalog_sales cs
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2451915 AND 2451925
    GROUP BY cd.cd_gender, ca.ca_state
),
catalog_returns_agg AS (
    SELECT
        cd.cd_gender AS gender,
        ca.ca_state AS state,
        COUNT(DISTINCT cr.cr_order_number) AS catalog_return_count,
        SUM(cr.cr_net_loss) AS total_catalog_return_loss,
        SUM(cr.cr_return_quantity) AS total_catalog_return_qty
    FROM catalog_returns cr
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2451915 AND 2451925
    GROUP BY cd.cd_gender, ca.ca_state
),
store_metrics AS (
    SELECT
        COALESCE(s.gender, r.gender) AS gender,
        COALESCE(s.state, r.state) AS state,
        s.store_sales_count,
        s.total_store_profit,
        r.store_return_count,
        r.total_store_return_loss,
        r.total_store_return_qty
    FROM store_sales_agg s
    FULL OUTER JOIN store_returns_agg r
      ON s.gender = r.gender AND s.state = r.state
),
catalog_metrics AS (
    SELECT
        COALESCE(s.gender, r.gender) AS gender,
        COALESCE(s.state, r.state) AS state,
        s.catalog_sales_count,
        s.total_catalog_profit,
        r.catalog_return_count,
        r.total_catalog_return_loss,
        r.total_catalog_return_qty
    FROM catalog_sales_agg s
    FULL OUTER JOIN catalog_returns_agg r
      ON s.gender = r.gender AND s.state = r.state
)
SELECT
    COALESCE(st.gender, ct.gender) AS gender,
    COALESCE(st.state, ct.state) AS state,
    st.store_sales_count,
    st.total_store_profit,
    st.store_return_count,
    st.total_store_return_loss,
    st.total_store_return_qty,
    ct.catalog_sales_count,
    ct.total_catalog_profit,
    ct.catalog_return_count,
    ct.total_catalog_return_loss,
    ct.total_catalog_return_qty,
    (COALESCE(st.total_store_profit, 0) - COALESCE(st.total_store_return_loss, 0) +
     COALESCE(ct.total_catalog_profit, 0) - COALESCE(ct.total_catalog_return_loss, 0)) AS net_profit_after_all_returns
FROM store_metrics st
FULL OUTER JOIN catalog_metrics ct
  ON st.gender = ct.gender AND st.state = ct.state
ORDER BY net_profit_after_all_returns DESC
LIMIT 100
