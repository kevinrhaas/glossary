--
-- PostgreSQL database dump
--

-- Dumped from database version 14.15 (Homebrew)
-- Dumped by pg_dump version 16.6 (Homebrew)

-- Started on 2025-07-30 16:09:19 CDT

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 7 (class 2615 OID 130907)
-- Name: fs_retbank_dimconsmktg; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA fs_retbank_dimconsmktg;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 223 (class 1259 OID 130923)
-- Name: dim_campaign; Type: TABLE; Schema: fs_retbank_dimconsmktg; Owner: -
--

CREATE TABLE fs_retbank_dimconsmktg.dim_campaign (
    campaign_sk integer NOT NULL,
    campaign_id character varying(50) NOT NULL,
    campaign_name character varying(255) NOT NULL,
    campaign_type character varying(50) NOT NULL,
    start_date date NOT NULL,
    end_date date,
    target_segment character varying(255),
    budget_amount numeric(14,4) NOT NULL,
    marketing_owner character varying(100),
    campaign_status character varying(50) NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    description text
);


--
-- TOC entry 3808 (class 0 OID 0)
-- Dependencies: 223
-- Name: TABLE dim_campaign; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON TABLE fs_retbank_dimconsmktg.dim_campaign IS 'Dimension table detailing marketing campaigns.';


--
-- TOC entry 3809 (class 0 OID 0)
-- Dependencies: 223
-- Name: COLUMN dim_campaign.campaign_sk; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_campaign.campaign_sk IS 'Surrogate primary key for campaign dimension.';


--
-- TOC entry 3810 (class 0 OID 0)
-- Dependencies: 223
-- Name: COLUMN dim_campaign.campaign_id; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_campaign.campaign_id IS 'Business unique campaign identifier.';


--
-- TOC entry 3811 (class 0 OID 0)
-- Dependencies: 223
-- Name: COLUMN dim_campaign.campaign_name; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_campaign.campaign_name IS 'Name of the campaign.';


--
-- TOC entry 3812 (class 0 OID 0)
-- Dependencies: 223
-- Name: COLUMN dim_campaign.campaign_type; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_campaign.campaign_type IS 'Type/category of campaign (e.g. email, sms, social).';


--
-- TOC entry 3813 (class 0 OID 0)
-- Dependencies: 223
-- Name: COLUMN dim_campaign.start_date; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_campaign.start_date IS 'Campaign start date.';


--
-- TOC entry 3814 (class 0 OID 0)
-- Dependencies: 223
-- Name: COLUMN dim_campaign.end_date; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_campaign.end_date IS 'Campaign end date.';


--
-- TOC entry 3815 (class 0 OID 0)
-- Dependencies: 223
-- Name: COLUMN dim_campaign.target_segment; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_campaign.target_segment IS 'Target customer segment for campaign.';


--
-- TOC entry 3816 (class 0 OID 0)
-- Dependencies: 223
-- Name: COLUMN dim_campaign.budget_amount; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_campaign.budget_amount IS 'Allocated budget for campaign.';


--
-- TOC entry 3817 (class 0 OID 0)
-- Dependencies: 223
-- Name: COLUMN dim_campaign.marketing_owner; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_campaign.marketing_owner IS 'Marketing campaign owner or team.';


--
-- TOC entry 3818 (class 0 OID 0)
-- Dependencies: 223
-- Name: COLUMN dim_campaign.campaign_status; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_campaign.campaign_status IS 'Current status of campaign (active, completed, cancelled).';


--
-- TOC entry 3819 (class 0 OID 0)
-- Dependencies: 223
-- Name: COLUMN dim_campaign.created_at; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_campaign.created_at IS 'Record creation timestamp.';


--
-- TOC entry 3820 (class 0 OID 0)
-- Dependencies: 223
-- Name: COLUMN dim_campaign.updated_at; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_campaign.updated_at IS 'Record last update timestamp.';


--
-- TOC entry 3821 (class 0 OID 0)
-- Dependencies: 223
-- Name: COLUMN dim_campaign.description; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_campaign.description IS 'Detailed description of the campaign.';


--
-- TOC entry 222 (class 1259 OID 130922)
-- Name: dim_campaign_campaign_sk_seq; Type: SEQUENCE; Schema: fs_retbank_dimconsmktg; Owner: -
--

CREATE SEQUENCE fs_retbank_dimconsmktg.dim_campaign_campaign_sk_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3822 (class 0 OID 0)
-- Dependencies: 222
-- Name: dim_campaign_campaign_sk_seq; Type: SEQUENCE OWNED BY; Schema: fs_retbank_dimconsmktg; Owner: -
--

ALTER SEQUENCE fs_retbank_dimconsmktg.dim_campaign_campaign_sk_seq OWNED BY fs_retbank_dimconsmktg.dim_campaign.campaign_sk;


--
-- TOC entry 231 (class 1259 OID 130987)
-- Name: dim_channel; Type: TABLE; Schema: fs_retbank_dimconsmktg; Owner: -
--

CREATE TABLE fs_retbank_dimconsmktg.dim_channel (
    channel_sk integer NOT NULL,
    channel_id character varying(50) NOT NULL,
    channel_name character varying(100) NOT NULL,
    channel_type character varying(100) NOT NULL,
    channel_description text,
    contact_number character varying(50),
    email_address character varying(255),
    url character varying(255),
    region character varying(100),
    is_digital boolean NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 3823 (class 0 OID 0)
-- Dependencies: 231
-- Name: TABLE dim_channel; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON TABLE fs_retbank_dimconsmktg.dim_channel IS 'Dimension table defining marketing campaign channels.';


--
-- TOC entry 3824 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN dim_channel.channel_sk; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_channel.channel_sk IS 'Surrogate primary key for channel dimension.';


--
-- TOC entry 3825 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN dim_channel.channel_id; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_channel.channel_id IS 'Business unique channel identifier.';


--
-- TOC entry 3826 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN dim_channel.channel_name; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_channel.channel_name IS 'Channel display name.';


--
-- TOC entry 3827 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN dim_channel.channel_type; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_channel.channel_type IS 'General channel type (digital, branch, call center, etc.).';


--
-- TOC entry 3828 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN dim_channel.channel_description; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_channel.channel_description IS 'Text description of channel.';


--
-- TOC entry 3829 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN dim_channel.contact_number; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_channel.contact_number IS 'Contact number for the channel if applicable.';


--
-- TOC entry 3830 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN dim_channel.email_address; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_channel.email_address IS 'Email address for channel contact if applicable.';


--
-- TOC entry 3831 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN dim_channel.url; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_channel.url IS 'Website or landing page URL for channel.';


--
-- TOC entry 3832 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN dim_channel.region; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_channel.region IS 'Geographic region served by channel.';


--
-- TOC entry 3833 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN dim_channel.is_digital; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_channel.is_digital IS 'Flag indicating if this is a digital channel.';


--
-- TOC entry 3834 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN dim_channel.created_at; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_channel.created_at IS 'Record creation timestamp.';


--
-- TOC entry 3835 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN dim_channel.updated_at; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_channel.updated_at IS 'Record last update timestamp.';


--
-- TOC entry 230 (class 1259 OID 130986)
-- Name: dim_channel_channel_sk_seq; Type: SEQUENCE; Schema: fs_retbank_dimconsmktg; Owner: -
--

CREATE SEQUENCE fs_retbank_dimconsmktg.dim_channel_channel_sk_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3836 (class 0 OID 0)
-- Dependencies: 230
-- Name: dim_channel_channel_sk_seq; Type: SEQUENCE OWNED BY; Schema: fs_retbank_dimconsmktg; Owner: -
--

ALTER SEQUENCE fs_retbank_dimconsmktg.dim_channel_channel_sk_seq OWNED BY fs_retbank_dimconsmktg.dim_channel.channel_sk;


--
-- TOC entry 225 (class 1259 OID 130939)
-- Name: dim_customer; Type: TABLE; Schema: fs_retbank_dimconsmktg; Owner: -
--

CREATE TABLE fs_retbank_dimconsmktg.dim_customer (
    customer_sk integer NOT NULL,
    customer_id character varying(50) NOT NULL,
    first_name character varying(100) NOT NULL,
    last_name character varying(100) NOT NULL,
    gender character(1),
    birth_date date NOT NULL,
    marital_status character varying(50),
    education_level character varying(100),
    occupation character varying(150),
    income_band character varying(50),
    address_line1 character varying(255),
    address_line2 character varying(255),
    city character varying(100),
    state character varying(100),
    postal_code character varying(20),
    country character varying(100),
    email character varying(255),
    phone_number character varying(50),
    customer_since date NOT NULL,
    preferred_language character varying(50),
    preferred_contact_method character varying(50),
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 3837 (class 0 OID 0)
-- Dependencies: 225
-- Name: TABLE dim_customer; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON TABLE fs_retbank_dimconsmktg.dim_customer IS 'Dimension table of customers receiving marketing campaigns.';


--
-- TOC entry 3838 (class 0 OID 0)
-- Dependencies: 225
-- Name: COLUMN dim_customer.customer_sk; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_customer.customer_sk IS 'Surrogate primary key for customer dimension.';


--
-- TOC entry 3839 (class 0 OID 0)
-- Dependencies: 225
-- Name: COLUMN dim_customer.customer_id; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_customer.customer_id IS 'Business unique customer identifier.';


--
-- TOC entry 3840 (class 0 OID 0)
-- Dependencies: 225
-- Name: COLUMN dim_customer.first_name; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_customer.first_name IS 'Customer first name.';


--
-- TOC entry 3841 (class 0 OID 0)
-- Dependencies: 225
-- Name: COLUMN dim_customer.last_name; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_customer.last_name IS 'Customer last name.';


--
-- TOC entry 3842 (class 0 OID 0)
-- Dependencies: 225
-- Name: COLUMN dim_customer.gender; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_customer.gender IS 'Customer gender (M/F/O).';


--
-- TOC entry 3843 (class 0 OID 0)
-- Dependencies: 225
-- Name: COLUMN dim_customer.birth_date; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_customer.birth_date IS 'Customer birth date.';


--
-- TOC entry 3844 (class 0 OID 0)
-- Dependencies: 225
-- Name: COLUMN dim_customer.marital_status; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_customer.marital_status IS 'Customer marital status.';


--
-- TOC entry 3845 (class 0 OID 0)
-- Dependencies: 225
-- Name: COLUMN dim_customer.education_level; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_customer.education_level IS 'Highest education level attained by customer.';


--
-- TOC entry 3846 (class 0 OID 0)
-- Dependencies: 225
-- Name: COLUMN dim_customer.occupation; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_customer.occupation IS 'Customer occupation.';


--
-- TOC entry 3847 (class 0 OID 0)
-- Dependencies: 225
-- Name: COLUMN dim_customer.income_band; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_customer.income_band IS 'Customer income band classification.';


--
-- TOC entry 3848 (class 0 OID 0)
-- Dependencies: 225
-- Name: COLUMN dim_customer.address_line1; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_customer.address_line1 IS 'Customer primary address line 1.';


--
-- TOC entry 3849 (class 0 OID 0)
-- Dependencies: 225
-- Name: COLUMN dim_customer.address_line2; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_customer.address_line2 IS 'Customer primary address line 2.';


--
-- TOC entry 3850 (class 0 OID 0)
-- Dependencies: 225
-- Name: COLUMN dim_customer.city; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_customer.city IS 'Customer city.';


--
-- TOC entry 3851 (class 0 OID 0)
-- Dependencies: 225
-- Name: COLUMN dim_customer.state; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_customer.state IS 'Customer state or province.';


--
-- TOC entry 3852 (class 0 OID 0)
-- Dependencies: 225
-- Name: COLUMN dim_customer.postal_code; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_customer.postal_code IS 'Customer postal/zip code.';


--
-- TOC entry 3853 (class 0 OID 0)
-- Dependencies: 225
-- Name: COLUMN dim_customer.country; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_customer.country IS 'Customer country.';


--
-- TOC entry 3854 (class 0 OID 0)
-- Dependencies: 225
-- Name: COLUMN dim_customer.email; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_customer.email IS 'Customer email address.';


--
-- TOC entry 3855 (class 0 OID 0)
-- Dependencies: 225
-- Name: COLUMN dim_customer.phone_number; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_customer.phone_number IS 'Customer phone number.';


--
-- TOC entry 3856 (class 0 OID 0)
-- Dependencies: 225
-- Name: COLUMN dim_customer.customer_since; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_customer.customer_since IS 'Date customer relationship started.';


--
-- TOC entry 3857 (class 0 OID 0)
-- Dependencies: 225
-- Name: COLUMN dim_customer.preferred_language; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_customer.preferred_language IS 'Preferred language for communications.';


--
-- TOC entry 3858 (class 0 OID 0)
-- Dependencies: 225
-- Name: COLUMN dim_customer.preferred_contact_method; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_customer.preferred_contact_method IS 'Preferred contact method for campaigns.';


--
-- TOC entry 3859 (class 0 OID 0)
-- Dependencies: 225
-- Name: COLUMN dim_customer.created_at; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_customer.created_at IS 'Record creation timestamp.';


--
-- TOC entry 3860 (class 0 OID 0)
-- Dependencies: 225
-- Name: COLUMN dim_customer.updated_at; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_customer.updated_at IS 'Record last update timestamp.';


--
-- TOC entry 224 (class 1259 OID 130938)
-- Name: dim_customer_customer_sk_seq; Type: SEQUENCE; Schema: fs_retbank_dimconsmktg; Owner: -
--

CREATE SEQUENCE fs_retbank_dimconsmktg.dim_customer_customer_sk_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3861 (class 0 OID 0)
-- Dependencies: 224
-- Name: dim_customer_customer_sk_seq; Type: SEQUENCE OWNED BY; Schema: fs_retbank_dimconsmktg; Owner: -
--

ALTER SEQUENCE fs_retbank_dimconsmktg.dim_customer_customer_sk_seq OWNED BY fs_retbank_dimconsmktg.dim_customer.customer_sk;


--
-- TOC entry 229 (class 1259 OID 130972)
-- Name: dim_product; Type: TABLE; Schema: fs_retbank_dimconsmktg; Owner: -
--

CREATE TABLE fs_retbank_dimconsmktg.dim_product (
    product_sk integer NOT NULL,
    product_id character varying(50) NOT NULL,
    product_name character varying(255) NOT NULL,
    product_category character varying(100) NOT NULL,
    product_type character varying(100),
    product_subtype character varying(100),
    interest_rate numeric(6,4),
    fee_type character varying(100),
    fee_amount numeric(14,4),
    eligibility_criteria text,
    product_launch_date date,
    product_discontinued_date date,
    credit_limit numeric(14,4),
    term_months integer,
    min_balance_required numeric(14,4),
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    description text
);


--
-- TOC entry 3862 (class 0 OID 0)
-- Dependencies: 229
-- Name: TABLE dim_product; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON TABLE fs_retbank_dimconsmktg.dim_product IS 'Dimension table detailing retail banking products.';


--
-- TOC entry 3863 (class 0 OID 0)
-- Dependencies: 229
-- Name: COLUMN dim_product.product_sk; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_product.product_sk IS 'Surrogate primary key for product dimension.';


--
-- TOC entry 3864 (class 0 OID 0)
-- Dependencies: 229
-- Name: COLUMN dim_product.product_id; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_product.product_id IS 'Business unique product identifier.';


--
-- TOC entry 3865 (class 0 OID 0)
-- Dependencies: 229
-- Name: COLUMN dim_product.product_name; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_product.product_name IS 'Name of the product.';


--
-- TOC entry 3866 (class 0 OID 0)
-- Dependencies: 229
-- Name: COLUMN dim_product.product_category; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_product.product_category IS 'High level product category (deposit, loan, credit card, etc.).';


--
-- TOC entry 3867 (class 0 OID 0)
-- Dependencies: 229
-- Name: COLUMN dim_product.product_type; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_product.product_type IS 'Type of product within category.';


--
-- TOC entry 3868 (class 0 OID 0)
-- Dependencies: 229
-- Name: COLUMN dim_product.product_subtype; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_product.product_subtype IS 'Sub classification within product type.';


--
-- TOC entry 3869 (class 0 OID 0)
-- Dependencies: 229
-- Name: COLUMN dim_product.interest_rate; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_product.interest_rate IS 'Interest rate applicable to product.';


--
-- TOC entry 3870 (class 0 OID 0)
-- Dependencies: 229
-- Name: COLUMN dim_product.fee_type; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_product.fee_type IS 'Type of fee charged for product.';


--
-- TOC entry 3871 (class 0 OID 0)
-- Dependencies: 229
-- Name: COLUMN dim_product.fee_amount; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_product.fee_amount IS 'Fee amount applicable.';


--
-- TOC entry 3872 (class 0 OID 0)
-- Dependencies: 229
-- Name: COLUMN dim_product.eligibility_criteria; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_product.eligibility_criteria IS 'Eligibility criteria text for product.';


--
-- TOC entry 3873 (class 0 OID 0)
-- Dependencies: 229
-- Name: COLUMN dim_product.product_launch_date; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_product.product_launch_date IS 'Date when product was launched.';


--
-- TOC entry 3874 (class 0 OID 0)
-- Dependencies: 229
-- Name: COLUMN dim_product.product_discontinued_date; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_product.product_discontinued_date IS 'Date when product was discontinued, if any.';


--
-- TOC entry 3875 (class 0 OID 0)
-- Dependencies: 229
-- Name: COLUMN dim_product.credit_limit; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_product.credit_limit IS 'Credit limit for credit products.';


--
-- TOC entry 3876 (class 0 OID 0)
-- Dependencies: 229
-- Name: COLUMN dim_product.term_months; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_product.term_months IS 'Term length for term products.';


--
-- TOC entry 3877 (class 0 OID 0)
-- Dependencies: 229
-- Name: COLUMN dim_product.min_balance_required; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_product.min_balance_required IS 'Minimum balance required for the product.';


--
-- TOC entry 3878 (class 0 OID 0)
-- Dependencies: 229
-- Name: COLUMN dim_product.created_at; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_product.created_at IS 'Record creation timestamp.';


--
-- TOC entry 3879 (class 0 OID 0)
-- Dependencies: 229
-- Name: COLUMN dim_product.updated_at; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_product.updated_at IS 'Record last update timestamp.';


--
-- TOC entry 3880 (class 0 OID 0)
-- Dependencies: 229
-- Name: COLUMN dim_product.description; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_product.description IS 'Additional description or notes about product.';


--
-- TOC entry 228 (class 1259 OID 130971)
-- Name: dim_product_product_sk_seq; Type: SEQUENCE; Schema: fs_retbank_dimconsmktg; Owner: -
--

CREATE SEQUENCE fs_retbank_dimconsmktg.dim_product_product_sk_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3881 (class 0 OID 0)
-- Dependencies: 228
-- Name: dim_product_product_sk_seq; Type: SEQUENCE OWNED BY; Schema: fs_retbank_dimconsmktg; Owner: -
--

ALTER SEQUENCE fs_retbank_dimconsmktg.dim_product_product_sk_seq OWNED BY fs_retbank_dimconsmktg.dim_product.product_sk;


--
-- TOC entry 233 (class 1259 OID 131002)
-- Name: dim_segment; Type: TABLE; Schema: fs_retbank_dimconsmktg; Owner: -
--

CREATE TABLE fs_retbank_dimconsmktg.dim_segment (
    segment_sk integer NOT NULL,
    segment_id character varying(50) NOT NULL,
    segment_name character varying(255) NOT NULL,
    segment_definition text NOT NULL,
    min_age integer,
    max_age integer,
    income_min numeric(14,4),
    income_max numeric(14,4),
    geography character varying(255),
    risk_level character varying(50),
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 3882 (class 0 OID 0)
-- Dependencies: 233
-- Name: TABLE dim_segment; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON TABLE fs_retbank_dimconsmktg.dim_segment IS 'Dimension table defining customer segments used for targeting campaigns.';


--
-- TOC entry 3883 (class 0 OID 0)
-- Dependencies: 233
-- Name: COLUMN dim_segment.segment_sk; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_segment.segment_sk IS 'Surrogate primary key for segment dimension.';


--
-- TOC entry 3884 (class 0 OID 0)
-- Dependencies: 233
-- Name: COLUMN dim_segment.segment_id; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_segment.segment_id IS 'Business unique identifier for segment.';


--
-- TOC entry 3885 (class 0 OID 0)
-- Dependencies: 233
-- Name: COLUMN dim_segment.segment_name; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_segment.segment_name IS 'Name of the segment.';


--
-- TOC entry 3886 (class 0 OID 0)
-- Dependencies: 233
-- Name: COLUMN dim_segment.segment_definition; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_segment.segment_definition IS 'Textual definition or logic of segment.';


--
-- TOC entry 3887 (class 0 OID 0)
-- Dependencies: 233
-- Name: COLUMN dim_segment.min_age; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_segment.min_age IS 'Minimum age for segment inclusion.';


--
-- TOC entry 3888 (class 0 OID 0)
-- Dependencies: 233
-- Name: COLUMN dim_segment.max_age; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_segment.max_age IS 'Maximum age for segment inclusion.';


--
-- TOC entry 3889 (class 0 OID 0)
-- Dependencies: 233
-- Name: COLUMN dim_segment.income_min; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_segment.income_min IS 'Minimum income for segment inclusion.';


--
-- TOC entry 3890 (class 0 OID 0)
-- Dependencies: 233
-- Name: COLUMN dim_segment.income_max; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_segment.income_max IS 'Maximum income for segment inclusion.';


--
-- TOC entry 3891 (class 0 OID 0)
-- Dependencies: 233
-- Name: COLUMN dim_segment.geography; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_segment.geography IS 'Geographic scope for segment.';


--
-- TOC entry 3892 (class 0 OID 0)
-- Dependencies: 233
-- Name: COLUMN dim_segment.risk_level; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_segment.risk_level IS 'Risk level associated with segment.';


--
-- TOC entry 3893 (class 0 OID 0)
-- Dependencies: 233
-- Name: COLUMN dim_segment.created_at; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_segment.created_at IS 'Record creation timestamp.';


--
-- TOC entry 3894 (class 0 OID 0)
-- Dependencies: 233
-- Name: COLUMN dim_segment.updated_at; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_segment.updated_at IS 'Record last update timestamp.';


--
-- TOC entry 232 (class 1259 OID 131001)
-- Name: dim_segment_segment_sk_seq; Type: SEQUENCE; Schema: fs_retbank_dimconsmktg; Owner: -
--

CREATE SEQUENCE fs_retbank_dimconsmktg.dim_segment_segment_sk_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3895 (class 0 OID 0)
-- Dependencies: 232
-- Name: dim_segment_segment_sk_seq; Type: SEQUENCE OWNED BY; Schema: fs_retbank_dimconsmktg; Owner: -
--

ALTER SEQUENCE fs_retbank_dimconsmktg.dim_segment_segment_sk_seq OWNED BY fs_retbank_dimconsmktg.dim_segment.segment_sk;


--
-- TOC entry 227 (class 1259 OID 130957)
-- Name: dim_time; Type: TABLE; Schema: fs_retbank_dimconsmktg; Owner: -
--

CREATE TABLE fs_retbank_dimconsmktg.dim_time (
    time_sk integer NOT NULL,
    date date NOT NULL,
    day_of_week integer NOT NULL,
    day_name character varying(10) NOT NULL,
    day_of_month integer NOT NULL,
    day_of_year integer NOT NULL,
    week_of_year integer NOT NULL,
    month integer NOT NULL,
    month_name character varying(15) NOT NULL,
    quarter integer NOT NULL,
    year integer NOT NULL,
    fiscal_year integer,
    fiscal_quarter integer,
    is_weekend boolean NOT NULL,
    holiday_flag boolean NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 3896 (class 0 OID 0)
-- Dependencies: 227
-- Name: TABLE dim_time; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON TABLE fs_retbank_dimconsmktg.dim_time IS 'Date dimension table for time granularity across all facts.';


--
-- TOC entry 3897 (class 0 OID 0)
-- Dependencies: 227
-- Name: COLUMN dim_time.time_sk; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_time.time_sk IS 'Surrogate primary key for time dimension.';


--
-- TOC entry 3898 (class 0 OID 0)
-- Dependencies: 227
-- Name: COLUMN dim_time.date; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_time.date IS 'Calendar date (business key).';


--
-- TOC entry 3899 (class 0 OID 0)
-- Dependencies: 227
-- Name: COLUMN dim_time.day_of_week; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_time.day_of_week IS 'Integer day of week (1=Monday).';


--
-- TOC entry 3900 (class 0 OID 0)
-- Dependencies: 227
-- Name: COLUMN dim_time.day_name; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_time.day_name IS 'Name of the day.';


--
-- TOC entry 3901 (class 0 OID 0)
-- Dependencies: 227
-- Name: COLUMN dim_time.day_of_month; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_time.day_of_month IS 'Day number within the month.';


--
-- TOC entry 3902 (class 0 OID 0)
-- Dependencies: 227
-- Name: COLUMN dim_time.day_of_year; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_time.day_of_year IS 'Day number within the year.';


--
-- TOC entry 3903 (class 0 OID 0)
-- Dependencies: 227
-- Name: COLUMN dim_time.week_of_year; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_time.week_of_year IS 'ISO week number of the year.';


--
-- TOC entry 3904 (class 0 OID 0)
-- Dependencies: 227
-- Name: COLUMN dim_time.month; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_time.month IS 'Month number (1-12).';


--
-- TOC entry 3905 (class 0 OID 0)
-- Dependencies: 227
-- Name: COLUMN dim_time.month_name; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_time.month_name IS 'Name of the month.';


--
-- TOC entry 3906 (class 0 OID 0)
-- Dependencies: 227
-- Name: COLUMN dim_time.quarter; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_time.quarter IS 'Quarter of the year (1-4).';


--
-- TOC entry 3907 (class 0 OID 0)
-- Dependencies: 227
-- Name: COLUMN dim_time.year; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_time.year IS 'Year of the date.';


--
-- TOC entry 3908 (class 0 OID 0)
-- Dependencies: 227
-- Name: COLUMN dim_time.fiscal_year; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_time.fiscal_year IS 'Fiscal year for financial reporting.';


--
-- TOC entry 3909 (class 0 OID 0)
-- Dependencies: 227
-- Name: COLUMN dim_time.fiscal_quarter; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_time.fiscal_quarter IS 'Fiscal quarter.';


--
-- TOC entry 3910 (class 0 OID 0)
-- Dependencies: 227
-- Name: COLUMN dim_time.is_weekend; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_time.is_weekend IS 'Flag if the day is weekend.';


--
-- TOC entry 3911 (class 0 OID 0)
-- Dependencies: 227
-- Name: COLUMN dim_time.holiday_flag; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_time.holiday_flag IS 'Flag if the date is a public holiday.';


--
-- TOC entry 3912 (class 0 OID 0)
-- Dependencies: 227
-- Name: COLUMN dim_time.created_at; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_time.created_at IS 'Record creation timestamp.';


--
-- TOC entry 3913 (class 0 OID 0)
-- Dependencies: 227
-- Name: COLUMN dim_time.updated_at; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.dim_time.updated_at IS 'Record last update timestamp.';


--
-- TOC entry 226 (class 1259 OID 130956)
-- Name: dim_time_time_sk_seq; Type: SEQUENCE; Schema: fs_retbank_dimconsmktg; Owner: -
--

CREATE SEQUENCE fs_retbank_dimconsmktg.dim_time_time_sk_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3914 (class 0 OID 0)
-- Dependencies: 226
-- Name: dim_time_time_sk_seq; Type: SEQUENCE OWNED BY; Schema: fs_retbank_dimconsmktg; Owner: -
--

ALTER SEQUENCE fs_retbank_dimconsmktg.dim_time_time_sk_seq OWNED BY fs_retbank_dimconsmktg.dim_time.time_sk;


--
-- TOC entry 221 (class 1259 OID 130909)
-- Name: fact_campaign_performance; Type: TABLE; Schema: fs_retbank_dimconsmktg; Owner: -
--

CREATE TABLE fs_retbank_dimconsmktg.fact_campaign_performance (
    campaign_perf_sk integer NOT NULL,
    campaign_sk integer NOT NULL,
    customer_sk integer NOT NULL,
    time_sk integer NOT NULL,
    product_sk integer NOT NULL,
    channel_sk integer NOT NULL,
    response_flag boolean NOT NULL,
    response_date date,
    spend_amount numeric(14,4) NOT NULL,
    revenue_amount numeric(14,4),
    impressions integer NOT NULL,
    clicks integer NOT NULL,
    conversions integer NOT NULL,
    net_profit numeric(14,4),
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 3915 (class 0 OID 0)
-- Dependencies: 221
-- Name: TABLE fact_campaign_performance; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON TABLE fs_retbank_dimconsmktg.fact_campaign_performance IS 'Fact table capturing marketing campaign performance metrics at customer-product-channel-time grain.';


--
-- TOC entry 3916 (class 0 OID 0)
-- Dependencies: 221
-- Name: COLUMN fact_campaign_performance.campaign_perf_sk; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.fact_campaign_performance.campaign_perf_sk IS 'Surrogate primary key for campaign performance fact.';


--
-- TOC entry 3917 (class 0 OID 0)
-- Dependencies: 221
-- Name: COLUMN fact_campaign_performance.campaign_sk; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.fact_campaign_performance.campaign_sk IS 'Foreign key to campaign dimension.';


--
-- TOC entry 3918 (class 0 OID 0)
-- Dependencies: 221
-- Name: COLUMN fact_campaign_performance.customer_sk; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.fact_campaign_performance.customer_sk IS 'Foreign key to customer dimension.';


--
-- TOC entry 3919 (class 0 OID 0)
-- Dependencies: 221
-- Name: COLUMN fact_campaign_performance.time_sk; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.fact_campaign_performance.time_sk IS 'Foreign key to time dimension (date granularity).';


--
-- TOC entry 3920 (class 0 OID 0)
-- Dependencies: 221
-- Name: COLUMN fact_campaign_performance.product_sk; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.fact_campaign_performance.product_sk IS 'Foreign key to product dimension.';


--
-- TOC entry 3921 (class 0 OID 0)
-- Dependencies: 221
-- Name: COLUMN fact_campaign_performance.channel_sk; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.fact_campaign_performance.channel_sk IS 'Foreign key to channel dimension.';


--
-- TOC entry 3922 (class 0 OID 0)
-- Dependencies: 221
-- Name: COLUMN fact_campaign_performance.response_flag; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.fact_campaign_performance.response_flag IS 'Flag indicating if customer responded to campaign.';


--
-- TOC entry 3923 (class 0 OID 0)
-- Dependencies: 221
-- Name: COLUMN fact_campaign_performance.response_date; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.fact_campaign_performance.response_date IS 'Date customer responded to campaign.';


--
-- TOC entry 3924 (class 0 OID 0)
-- Dependencies: 221
-- Name: COLUMN fact_campaign_performance.spend_amount; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.fact_campaign_performance.spend_amount IS 'Cost incurred for this campaign exposure.';


--
-- TOC entry 3925 (class 0 OID 0)
-- Dependencies: 221
-- Name: COLUMN fact_campaign_performance.revenue_amount; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.fact_campaign_performance.revenue_amount IS 'Revenue generated attributed to this campaign exposure.';


--
-- TOC entry 3926 (class 0 OID 0)
-- Dependencies: 221
-- Name: COLUMN fact_campaign_performance.impressions; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.fact_campaign_performance.impressions IS 'Number of times campaign was shown to the customer.';


--
-- TOC entry 3927 (class 0 OID 0)
-- Dependencies: 221
-- Name: COLUMN fact_campaign_performance.clicks; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.fact_campaign_performance.clicks IS 'Number of clicks from the customer on campaign.';


--
-- TOC entry 3928 (class 0 OID 0)
-- Dependencies: 221
-- Name: COLUMN fact_campaign_performance.conversions; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.fact_campaign_performance.conversions IS 'Number of conversions resulting from campaign exposure.';


--
-- TOC entry 3929 (class 0 OID 0)
-- Dependencies: 221
-- Name: COLUMN fact_campaign_performance.net_profit; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.fact_campaign_performance.net_profit IS 'Net profit calculated for this campaign exposure.';


--
-- TOC entry 3930 (class 0 OID 0)
-- Dependencies: 221
-- Name: COLUMN fact_campaign_performance.created_at; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.fact_campaign_performance.created_at IS 'Record creation timestamp.';


--
-- TOC entry 3931 (class 0 OID 0)
-- Dependencies: 221
-- Name: COLUMN fact_campaign_performance.updated_at; Type: COMMENT; Schema: fs_retbank_dimconsmktg; Owner: -
--

COMMENT ON COLUMN fs_retbank_dimconsmktg.fact_campaign_performance.updated_at IS 'Record last update timestamp.';


--
-- TOC entry 220 (class 1259 OID 130908)
-- Name: fact_campaign_performance_campaign_perf_sk_seq; Type: SEQUENCE; Schema: fs_retbank_dimconsmktg; Owner: -
--

CREATE SEQUENCE fs_retbank_dimconsmktg.fact_campaign_performance_campaign_perf_sk_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3932 (class 0 OID 0)
-- Dependencies: 220
-- Name: fact_campaign_performance_campaign_perf_sk_seq; Type: SEQUENCE OWNED BY; Schema: fs_retbank_dimconsmktg; Owner: -
--

ALTER SEQUENCE fs_retbank_dimconsmktg.fact_campaign_performance_campaign_perf_sk_seq OWNED BY fs_retbank_dimconsmktg.fact_campaign_performance.campaign_perf_sk;


--
-- TOC entry 3578 (class 2604 OID 130926)
-- Name: dim_campaign campaign_sk; Type: DEFAULT; Schema: fs_retbank_dimconsmktg; Owner: -
--

ALTER TABLE ONLY fs_retbank_dimconsmktg.dim_campaign ALTER COLUMN campaign_sk SET DEFAULT nextval('fs_retbank_dimconsmktg.dim_campaign_campaign_sk_seq'::regclass);


--
-- TOC entry 3590 (class 2604 OID 130990)
-- Name: dim_channel channel_sk; Type: DEFAULT; Schema: fs_retbank_dimconsmktg; Owner: -
--

ALTER TABLE ONLY fs_retbank_dimconsmktg.dim_channel ALTER COLUMN channel_sk SET DEFAULT nextval('fs_retbank_dimconsmktg.dim_channel_channel_sk_seq'::regclass);


--
-- TOC entry 3581 (class 2604 OID 130942)
-- Name: dim_customer customer_sk; Type: DEFAULT; Schema: fs_retbank_dimconsmktg; Owner: -
--

ALTER TABLE ONLY fs_retbank_dimconsmktg.dim_customer ALTER COLUMN customer_sk SET DEFAULT nextval('fs_retbank_dimconsmktg.dim_customer_customer_sk_seq'::regclass);


--
-- TOC entry 3587 (class 2604 OID 130975)
-- Name: dim_product product_sk; Type: DEFAULT; Schema: fs_retbank_dimconsmktg; Owner: -
--

ALTER TABLE ONLY fs_retbank_dimconsmktg.dim_product ALTER COLUMN product_sk SET DEFAULT nextval('fs_retbank_dimconsmktg.dim_product_product_sk_seq'::regclass);


--
-- TOC entry 3593 (class 2604 OID 131005)
-- Name: dim_segment segment_sk; Type: DEFAULT; Schema: fs_retbank_dimconsmktg; Owner: -
--

ALTER TABLE ONLY fs_retbank_dimconsmktg.dim_segment ALTER COLUMN segment_sk SET DEFAULT nextval('fs_retbank_dimconsmktg.dim_segment_segment_sk_seq'::regclass);


--
-- TOC entry 3584 (class 2604 OID 130960)
-- Name: dim_time time_sk; Type: DEFAULT; Schema: fs_retbank_dimconsmktg; Owner: -
--

ALTER TABLE ONLY fs_retbank_dimconsmktg.dim_time ALTER COLUMN time_sk SET DEFAULT nextval('fs_retbank_dimconsmktg.dim_time_time_sk_seq'::regclass);


--
-- TOC entry 3575 (class 2604 OID 130912)
-- Name: fact_campaign_performance campaign_perf_sk; Type: DEFAULT; Schema: fs_retbank_dimconsmktg; Owner: -
--

ALTER TABLE ONLY fs_retbank_dimconsmktg.fact_campaign_performance ALTER COLUMN campaign_perf_sk SET DEFAULT nextval('fs_retbank_dimconsmktg.fact_campaign_performance_campaign_perf_sk_seq'::regclass);


--
-- TOC entry 3792 (class 0 OID 130923)
-- Dependencies: 223
-- Data for Name: dim_campaign; Type: TABLE DATA; Schema: fs_retbank_dimconsmktg; Owner: -
--



--
-- TOC entry 3800 (class 0 OID 130987)
-- Dependencies: 231
-- Data for Name: dim_channel; Type: TABLE DATA; Schema: fs_retbank_dimconsmktg; Owner: -
--



--
-- TOC entry 3794 (class 0 OID 130939)
-- Dependencies: 225
-- Data for Name: dim_customer; Type: TABLE DATA; Schema: fs_retbank_dimconsmktg; Owner: -
--



--
-- TOC entry 3798 (class 0 OID 130972)
-- Dependencies: 229
-- Data for Name: dim_product; Type: TABLE DATA; Schema: fs_retbank_dimconsmktg; Owner: -
--



--
-- TOC entry 3802 (class 0 OID 131002)
-- Dependencies: 233
-- Data for Name: dim_segment; Type: TABLE DATA; Schema: fs_retbank_dimconsmktg; Owner: -
--



--
-- TOC entry 3796 (class 0 OID 130957)
-- Dependencies: 227
-- Data for Name: dim_time; Type: TABLE DATA; Schema: fs_retbank_dimconsmktg; Owner: -
--



--
-- TOC entry 3790 (class 0 OID 130909)
-- Dependencies: 221
-- Data for Name: fact_campaign_performance; Type: TABLE DATA; Schema: fs_retbank_dimconsmktg; Owner: -
--



--
-- TOC entry 3933 (class 0 OID 0)
-- Dependencies: 222
-- Name: dim_campaign_campaign_sk_seq; Type: SEQUENCE SET; Schema: fs_retbank_dimconsmktg; Owner: -
--

SELECT pg_catalog.setval('fs_retbank_dimconsmktg.dim_campaign_campaign_sk_seq', 1, false);


--
-- TOC entry 3934 (class 0 OID 0)
-- Dependencies: 230
-- Name: dim_channel_channel_sk_seq; Type: SEQUENCE SET; Schema: fs_retbank_dimconsmktg; Owner: -
--

SELECT pg_catalog.setval('fs_retbank_dimconsmktg.dim_channel_channel_sk_seq', 1, false);


--
-- TOC entry 3935 (class 0 OID 0)
-- Dependencies: 224
-- Name: dim_customer_customer_sk_seq; Type: SEQUENCE SET; Schema: fs_retbank_dimconsmktg; Owner: -
--

SELECT pg_catalog.setval('fs_retbank_dimconsmktg.dim_customer_customer_sk_seq', 1, false);


--
-- TOC entry 3936 (class 0 OID 0)
-- Dependencies: 228
-- Name: dim_product_product_sk_seq; Type: SEQUENCE SET; Schema: fs_retbank_dimconsmktg; Owner: -
--

SELECT pg_catalog.setval('fs_retbank_dimconsmktg.dim_product_product_sk_seq', 1, false);


--
-- TOC entry 3937 (class 0 OID 0)
-- Dependencies: 232
-- Name: dim_segment_segment_sk_seq; Type: SEQUENCE SET; Schema: fs_retbank_dimconsmktg; Owner: -
--

SELECT pg_catalog.setval('fs_retbank_dimconsmktg.dim_segment_segment_sk_seq', 1, false);


--
-- TOC entry 3938 (class 0 OID 0)
-- Dependencies: 226
-- Name: dim_time_time_sk_seq; Type: SEQUENCE SET; Schema: fs_retbank_dimconsmktg; Owner: -
--

SELECT pg_catalog.setval('fs_retbank_dimconsmktg.dim_time_time_sk_seq', 1, false);


--
-- TOC entry 3939 (class 0 OID 0)
-- Dependencies: 220
-- Name: fact_campaign_performance_campaign_perf_sk_seq; Type: SEQUENCE SET; Schema: fs_retbank_dimconsmktg; Owner: -
--

SELECT pg_catalog.setval('fs_retbank_dimconsmktg.fact_campaign_performance_campaign_perf_sk_seq', 1, false);


--
-- TOC entry 3604 (class 2606 OID 130934)
-- Name: dim_campaign dim_campaign_campaign_id_key; Type: CONSTRAINT; Schema: fs_retbank_dimconsmktg; Owner: -
--

ALTER TABLE ONLY fs_retbank_dimconsmktg.dim_campaign
    ADD CONSTRAINT dim_campaign_campaign_id_key UNIQUE (campaign_id);


--
-- TOC entry 3606 (class 2606 OID 130932)
-- Name: dim_campaign dim_campaign_pkey; Type: CONSTRAINT; Schema: fs_retbank_dimconsmktg; Owner: -
--

ALTER TABLE ONLY fs_retbank_dimconsmktg.dim_campaign
    ADD CONSTRAINT dim_campaign_pkey PRIMARY KEY (campaign_sk);


--
-- TOC entry 3634 (class 2606 OID 130998)
-- Name: dim_channel dim_channel_channel_id_key; Type: CONSTRAINT; Schema: fs_retbank_dimconsmktg; Owner: -
--

ALTER TABLE ONLY fs_retbank_dimconsmktg.dim_channel
    ADD CONSTRAINT dim_channel_channel_id_key UNIQUE (channel_id);


--
-- TOC entry 3636 (class 2606 OID 130996)
-- Name: dim_channel dim_channel_pkey; Type: CONSTRAINT; Schema: fs_retbank_dimconsmktg; Owner: -
--

ALTER TABLE ONLY fs_retbank_dimconsmktg.dim_channel
    ADD CONSTRAINT dim_channel_pkey PRIMARY KEY (channel_sk);


--
-- TOC entry 3611 (class 2606 OID 130950)
-- Name: dim_customer dim_customer_customer_id_key; Type: CONSTRAINT; Schema: fs_retbank_dimconsmktg; Owner: -
--

ALTER TABLE ONLY fs_retbank_dimconsmktg.dim_customer
    ADD CONSTRAINT dim_customer_customer_id_key UNIQUE (customer_id);


--
-- TOC entry 3613 (class 2606 OID 130948)
-- Name: dim_customer dim_customer_pkey; Type: CONSTRAINT; Schema: fs_retbank_dimconsmktg; Owner: -
--

ALTER TABLE ONLY fs_retbank_dimconsmktg.dim_customer
    ADD CONSTRAINT dim_customer_pkey PRIMARY KEY (customer_sk);


--
-- TOC entry 3628 (class 2606 OID 130981)
-- Name: dim_product dim_product_pkey; Type: CONSTRAINT; Schema: fs_retbank_dimconsmktg; Owner: -
--

ALTER TABLE ONLY fs_retbank_dimconsmktg.dim_product
    ADD CONSTRAINT dim_product_pkey PRIMARY KEY (product_sk);


--
-- TOC entry 3630 (class 2606 OID 130983)
-- Name: dim_product dim_product_product_id_key; Type: CONSTRAINT; Schema: fs_retbank_dimconsmktg; Owner: -
--

ALTER TABLE ONLY fs_retbank_dimconsmktg.dim_product
    ADD CONSTRAINT dim_product_product_id_key UNIQUE (product_id);


--
-- TOC entry 3640 (class 2606 OID 131011)
-- Name: dim_segment dim_segment_pkey; Type: CONSTRAINT; Schema: fs_retbank_dimconsmktg; Owner: -
--

ALTER TABLE ONLY fs_retbank_dimconsmktg.dim_segment
    ADD CONSTRAINT dim_segment_pkey PRIMARY KEY (segment_sk);


--
-- TOC entry 3642 (class 2606 OID 131013)
-- Name: dim_segment dim_segment_segment_id_key; Type: CONSTRAINT; Schema: fs_retbank_dimconsmktg; Owner: -
--

ALTER TABLE ONLY fs_retbank_dimconsmktg.dim_segment
    ADD CONSTRAINT dim_segment_segment_id_key UNIQUE (segment_id);


--
-- TOC entry 3620 (class 2606 OID 130966)
-- Name: dim_time dim_time_date_key; Type: CONSTRAINT; Schema: fs_retbank_dimconsmktg; Owner: -
--

ALTER TABLE ONLY fs_retbank_dimconsmktg.dim_time
    ADD CONSTRAINT dim_time_date_key UNIQUE (date);


--
-- TOC entry 3622 (class 2606 OID 130964)
-- Name: dim_time dim_time_pkey; Type: CONSTRAINT; Schema: fs_retbank_dimconsmktg; Owner: -
--

ALTER TABLE ONLY fs_retbank_dimconsmktg.dim_time
    ADD CONSTRAINT dim_time_pkey PRIMARY KEY (time_sk);


--
-- TOC entry 3597 (class 2606 OID 130916)
-- Name: fact_campaign_performance fact_campaign_performance_pkey; Type: CONSTRAINT; Schema: fs_retbank_dimconsmktg; Owner: -
--

ALTER TABLE ONLY fs_retbank_dimconsmktg.fact_campaign_performance
    ADD CONSTRAINT fact_campaign_performance_pkey PRIMARY KEY (campaign_perf_sk);


--
-- TOC entry 3607 (class 1259 OID 130935)
-- Name: idx_dim_campaign_campaignid; Type: INDEX; Schema: fs_retbank_dimconsmktg; Owner: -
--

CREATE INDEX idx_dim_campaign_campaignid ON fs_retbank_dimconsmktg.dim_campaign USING btree (campaign_id);


--
-- TOC entry 3608 (class 1259 OID 130937)
-- Name: idx_dim_campaign_campaignstatus; Type: INDEX; Schema: fs_retbank_dimconsmktg; Owner: -
--

CREATE INDEX idx_dim_campaign_campaignstatus ON fs_retbank_dimconsmktg.dim_campaign USING btree (campaign_status);


--
-- TOC entry 3609 (class 1259 OID 130936)
-- Name: idx_dim_campaign_campaigntype; Type: INDEX; Schema: fs_retbank_dimconsmktg; Owner: -
--

CREATE INDEX idx_dim_campaign_campaigntype ON fs_retbank_dimconsmktg.dim_campaign USING btree (campaign_type);


--
-- TOC entry 3637 (class 1259 OID 130999)
-- Name: idx_dim_channel_channeltype; Type: INDEX; Schema: fs_retbank_dimconsmktg; Owner: -
--

CREATE INDEX idx_dim_channel_channeltype ON fs_retbank_dimconsmktg.dim_channel USING btree (channel_type);


--
-- TOC entry 3638 (class 1259 OID 131000)
-- Name: idx_dim_channel_isdigital; Type: INDEX; Schema: fs_retbank_dimconsmktg; Owner: -
--

CREATE INDEX idx_dim_channel_isdigital ON fs_retbank_dimconsmktg.dim_channel USING btree (is_digital);


--
-- TOC entry 3614 (class 1259 OID 130953)
-- Name: idx_dim_customer_city; Type: INDEX; Schema: fs_retbank_dimconsmktg; Owner: -
--

CREATE INDEX idx_dim_customer_city ON fs_retbank_dimconsmktg.dim_customer USING btree (city);


--
-- TOC entry 3615 (class 1259 OID 130955)
-- Name: idx_dim_customer_country; Type: INDEX; Schema: fs_retbank_dimconsmktg; Owner: -
--

CREATE INDEX idx_dim_customer_country ON fs_retbank_dimconsmktg.dim_customer USING btree (country);


--
-- TOC entry 3616 (class 1259 OID 130951)
-- Name: idx_dim_customer_customerid; Type: INDEX; Schema: fs_retbank_dimconsmktg; Owner: -
--

CREATE INDEX idx_dim_customer_customerid ON fs_retbank_dimconsmktg.dim_customer USING btree (customer_id);


--
-- TOC entry 3617 (class 1259 OID 130952)
-- Name: idx_dim_customer_email; Type: INDEX; Schema: fs_retbank_dimconsmktg; Owner: -
--

CREATE INDEX idx_dim_customer_email ON fs_retbank_dimconsmktg.dim_customer USING btree (email);


--
-- TOC entry 3618 (class 1259 OID 130954)
-- Name: idx_dim_customer_state; Type: INDEX; Schema: fs_retbank_dimconsmktg; Owner: -
--

CREATE INDEX idx_dim_customer_state ON fs_retbank_dimconsmktg.dim_customer USING btree (state);


--
-- TOC entry 3631 (class 1259 OID 130984)
-- Name: idx_dim_product_category; Type: INDEX; Schema: fs_retbank_dimconsmktg; Owner: -
--

CREATE INDEX idx_dim_product_category ON fs_retbank_dimconsmktg.dim_product USING btree (product_category);


--
-- TOC entry 3632 (class 1259 OID 130985)
-- Name: idx_dim_product_type; Type: INDEX; Schema: fs_retbank_dimconsmktg; Owner: -
--

CREATE INDEX idx_dim_product_type ON fs_retbank_dimconsmktg.dim_product USING btree (product_type);


--
-- TOC entry 3643 (class 1259 OID 131014)
-- Name: idx_dim_segment_geography; Type: INDEX; Schema: fs_retbank_dimconsmktg; Owner: -
--

CREATE INDEX idx_dim_segment_geography ON fs_retbank_dimconsmktg.dim_segment USING btree (geography);


--
-- TOC entry 3644 (class 1259 OID 131015)
-- Name: idx_dim_segment_risklevel; Type: INDEX; Schema: fs_retbank_dimconsmktg; Owner: -
--

CREATE INDEX idx_dim_segment_risklevel ON fs_retbank_dimconsmktg.dim_segment USING btree (risk_level);


--
-- TOC entry 3623 (class 1259 OID 130970)
-- Name: idx_dim_time_dayofweek; Type: INDEX; Schema: fs_retbank_dimconsmktg; Owner: -
--

CREATE INDEX idx_dim_time_dayofweek ON fs_retbank_dimconsmktg.dim_time USING btree (day_of_week);


--
-- TOC entry 3624 (class 1259 OID 130969)
-- Name: idx_dim_time_month; Type: INDEX; Schema: fs_retbank_dimconsmktg; Owner: -
--

CREATE INDEX idx_dim_time_month ON fs_retbank_dimconsmktg.dim_time USING btree (month);


--
-- TOC entry 3625 (class 1259 OID 130968)
-- Name: idx_dim_time_year; Type: INDEX; Schema: fs_retbank_dimconsmktg; Owner: -
--

CREATE INDEX idx_dim_time_year ON fs_retbank_dimconsmktg.dim_time USING btree (year);


--
-- TOC entry 3598 (class 1259 OID 130918)
-- Name: idx_fact_campaign_performance_campaignsk; Type: INDEX; Schema: fs_retbank_dimconsmktg; Owner: -
--

CREATE INDEX idx_fact_campaign_performance_campaignsk ON fs_retbank_dimconsmktg.fact_campaign_performance USING btree (campaign_sk);


--
-- TOC entry 3599 (class 1259 OID 130921)
-- Name: idx_fact_campaign_performance_channelsk; Type: INDEX; Schema: fs_retbank_dimconsmktg; Owner: -
--

CREATE INDEX idx_fact_campaign_performance_channelsk ON fs_retbank_dimconsmktg.fact_campaign_performance USING btree (channel_sk);


--
-- TOC entry 3600 (class 1259 OID 130917)
-- Name: idx_fact_campaign_performance_custsk; Type: INDEX; Schema: fs_retbank_dimconsmktg; Owner: -
--

CREATE INDEX idx_fact_campaign_performance_custsk ON fs_retbank_dimconsmktg.fact_campaign_performance USING btree (customer_sk);


--
-- TOC entry 3601 (class 1259 OID 130920)
-- Name: idx_fact_campaign_performance_productsk; Type: INDEX; Schema: fs_retbank_dimconsmktg; Owner: -
--

CREATE INDEX idx_fact_campaign_performance_productsk ON fs_retbank_dimconsmktg.fact_campaign_performance USING btree (product_sk);


--
-- TOC entry 3602 (class 1259 OID 130919)
-- Name: idx_fact_campaign_performance_timesk; Type: INDEX; Schema: fs_retbank_dimconsmktg; Owner: -
--

CREATE INDEX idx_fact_campaign_performance_timesk ON fs_retbank_dimconsmktg.fact_campaign_performance USING btree (time_sk);


--
-- TOC entry 3626 (class 1259 OID 130967)
-- Name: uidx_dim_time_date; Type: INDEX; Schema: fs_retbank_dimconsmktg; Owner: -
--

CREATE UNIQUE INDEX uidx_dim_time_date ON fs_retbank_dimconsmktg.dim_time USING btree (date);


--
-- TOC entry 3645 (class 2606 OID 131027)
-- Name: fact_campaign_performance fk_fact_campaign_performance_campaign; Type: FK CONSTRAINT; Schema: fs_retbank_dimconsmktg; Owner: -
--

ALTER TABLE ONLY fs_retbank_dimconsmktg.fact_campaign_performance
    ADD CONSTRAINT fk_fact_campaign_performance_campaign FOREIGN KEY (campaign_sk) REFERENCES fs_retbank_dimconsmktg.dim_campaign(campaign_sk);


--
-- TOC entry 3646 (class 2606 OID 131047)
-- Name: fact_campaign_performance fk_fact_campaign_performance_channel; Type: FK CONSTRAINT; Schema: fs_retbank_dimconsmktg; Owner: -
--

ALTER TABLE ONLY fs_retbank_dimconsmktg.fact_campaign_performance
    ADD CONSTRAINT fk_fact_campaign_performance_channel FOREIGN KEY (channel_sk) REFERENCES fs_retbank_dimconsmktg.dim_channel(channel_sk);


--
-- TOC entry 3647 (class 2606 OID 131032)
-- Name: fact_campaign_performance fk_fact_campaign_performance_customer; Type: FK CONSTRAINT; Schema: fs_retbank_dimconsmktg; Owner: -
--

ALTER TABLE ONLY fs_retbank_dimconsmktg.fact_campaign_performance
    ADD CONSTRAINT fk_fact_campaign_performance_customer FOREIGN KEY (customer_sk) REFERENCES fs_retbank_dimconsmktg.dim_customer(customer_sk);


--
-- TOC entry 3648 (class 2606 OID 131042)
-- Name: fact_campaign_performance fk_fact_campaign_performance_product; Type: FK CONSTRAINT; Schema: fs_retbank_dimconsmktg; Owner: -
--

ALTER TABLE ONLY fs_retbank_dimconsmktg.fact_campaign_performance
    ADD CONSTRAINT fk_fact_campaign_performance_product FOREIGN KEY (product_sk) REFERENCES fs_retbank_dimconsmktg.dim_product(product_sk);


--
-- TOC entry 3649 (class 2606 OID 131037)
-- Name: fact_campaign_performance fk_fact_campaign_performance_time; Type: FK CONSTRAINT; Schema: fs_retbank_dimconsmktg; Owner: -
--

ALTER TABLE ONLY fs_retbank_dimconsmktg.fact_campaign_performance
    ADD CONSTRAINT fk_fact_campaign_performance_time FOREIGN KEY (time_sk) REFERENCES fs_retbank_dimconsmktg.dim_time(time_sk);


-- Completed on 2025-07-30 16:09:27 CDT

--
-- PostgreSQL database dump complete
--

