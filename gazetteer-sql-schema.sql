DROP TABLE IF EXISTS s_time_period;
DROP TABLE IF EXISTS s_supplemental_note;
DROP TABLE IF EXISTS s_related_feature;
DROP TABLE IF EXISTS s_pronunciation;
DROP TABLE IF EXISTS s_name_toponymic_authority;
DROP TABLE IF EXISTS s_name_to_time_period;
DROP TABLE IF EXISTS s_name_to_link_info_reference;
DROP TABLE IF EXISTS s_location_geometry;
DROP TABLE IF EXISTS s_feature_name;
DROP TABLE IF EXISTS s_location;
DROP TABLE IF EXISTS s_feature_link;
DROP TABLE IF EXISTS s_feature_data;
DROP TABLE IF EXISTS s_feature_code;
DROP TABLE IF EXISTS s_feature;
DROP TABLE IF EXISTS s_description;
DROP TABLE IF EXISTS s_classification;
DROP TABLE IF EXISTS s_address;
DROP TABLE IF EXISTS g_supplemental_note;
DROP TABLE IF EXISTS g_source;
DROP TABLE IF EXISTS g_related_feature;
DROP TABLE IF EXISTS g_pronunciation;
DROP TABLE IF EXISTS g_name_toponymic_authority;
DROP TABLE IF EXISTS g_name_to_time_period;
DROP TABLE IF EXISTS g_name_to_link_info_reference;
DROP TABLE IF EXISTS g_name_abbreviation;
DROP TABLE IF EXISTS g_location_geometry;
DROP TABLE IF EXISTS g_location;
DROP TABLE IF EXISTS g_feature_name;
DROP TABLE IF EXISTS g_feature_link;
DROP TABLE IF EXISTS g_feature_data;
DROP TABLE IF EXISTS g_feature_code;
DROP TABLE IF EXISTS g_entry_source;
DROP TABLE IF EXISTS g_encoded_date;
DROP TABLE IF EXISTS g_description;
DROP TABLE IF EXISTS g_classification;
DROP TABLE IF EXISTS g_begin_end_date;
DROP TABLE IF EXISTS g_address;
DROP TABLE IF EXISTS g_feature;
DROP TABLE IF EXISTS g_time_period_to_period_name;
DROP TABLE IF EXISTS g_time_date_range;
DROP TABLE IF EXISTS g_collection;
DROP TABLE IF EXISTS l_time_period_name;
DROP TABLE IF EXISTS g_time_period;
DROP TABLE IF EXISTS l_source_reference;
DROP TABLE IF EXISTS l_scheme_term_rank;
DROP TABLE IF EXISTS l_scheme_term_parent;
DROP TABLE IF EXISTS l_scheme_term;
DROP TABLE IF EXISTS l_language;
DROP TABLE IF EXISTS l_scheme;
DROP TABLE IF EXISTS l_contributor;
DROP TABLE IF EXISTS l_author;

CREATE TABLE l_author (
   author_id LONG NOT NULL PRIMARY KEY,
   author VARCHAR(100) NOT NULL
);

CREATE TABLE l_contributor (
   contributor_id LONG NOT NULL PRIMARY KEY,
   organization_name VARCHAR(100) NOT NULL, -- Statement identifying the responsible organization.
   site_title VARCHAR(100), -- Brief title for the contributor's website.
   contributor_url URI(500), -- Network address for the contributor's website.
   contact_name VARCHAR(100), -- Name of position or person who can be contacted about the entry, now and in the future.
   street_address VARCHAR(80), -- Street address for the physical location.
   city VARCHAR(80), -- city 
   state_province VARCHAR(80) NOT NULL, -- State or province name for the address.
   postal_code VARCHAR(20), -- postal_code Postal code for the address.
   country VARCHAR(20) -- Country for the address.
);

CREATE TABLE l_scheme (
   scheme_id LONG NOT NULL PRIMARY KEY,
   scheme_name VARCHAR(100) NOT NULL,
   scheme_abbreviation VARCHAR(20),
   scheme_version VARCHAR(20) NOT NULL,
   download_url URI(500) NULL,
   download_mime_type VARCHAR(20),
   service_url URI(500),
   service_protocol_name VARCHAR(80),
   service_protocol_url URI(500),
   web_interface_url URI(500),
   offline_source_citation TEXT(500),
   scheme_type VARCHAR(20) NOT NULL,
   primary_classification_scheme BOOLEAN NOT NULL -- Whether this is the primary classification scheme.
);

CREATE TABLE l_language (
   language_id LONG NOT NULL PRIMARY KEY,
   language_code VARCHAR(3) NOT NULL, -- Two or three letter code for the language of the placename. Preference is given to the native language of the place when the name is widely used in other languages as well. Example: 'Paris' has the language code FRA or FRE.
   language_scheme_id LONG NOT NULL,
   FOREIGN KEY (language_scheme_id) REFERENCES l_scheme
);

CREATE TABLE l_scheme_term (
   scheme_term_id LONG NOT NULL PRIMARY KEY,
   scheme_id LONG NOT NULL,
   term VARCHAR(255) NOT NULL,
   external_scheme_term_id VARCHAR(80), -- Term identifier in the external scheme.
   term_order_number LONG,
   term_rank_number LONG,
   FOREIGN KEY (scheme_id) REFERENCES l_scheme
);

CREATE TABLE l_scheme_term_parent (
   scheme_term_parent_id LONG NOT NULL PRIMARY KEY,
   scheme_term_id LONG NOT NULL,
   parent_scheme_term_id LONG NOT NULL,
   FOREIGN KEY (scheme_term_id) REFERENCES l_scheme_term,
   FOREIGN KEY (parent_scheme_term_id) REFERENCES l_scheme_term
);

CREATE TABLE l_scheme_term_rank (
   scheme_term_id LONG NOT NULL PRIMARY KEY,
   FTT_order1 LONG,
   FTT_order2 LONG,
   FOREIGN KEY (scheme_term_id) REFERENCES l_scheme_term
);

CREATE TABLE l_source_reference (
   source_reference_id LONG NOT NULL  PRIMARY KEY, -- Edition or version number of the source document.
   citation TEXT(500), -- Network address for an online source.
   reference_author_id LONG NULL,
   reference_date DATE, -- The date of publication or date of issue or creation.
   ibsn VARCHAR(80),
   issn VARCHAR(80),
   reference_url URI(50), -- related URI, aka URL
   FOREIGN KEY (reference_author_id) REFERENCES l_author 
);

CREATE TABLE g_time_period (
   time_period_id LONG NOT NULL PRIMARY KEY,
   status_term_id LONG NOT NULL,
   FOREIGN KEY (status_term_id) REFERENCES l_scheme_term
);

CREATE TABLE l_time_period_name (
   time_period_name_id LONG NOT NULL PRIMARY KEY,
   time_period_name VARCHAR(100) NOT NULL, -- Name of a time period, such as 'Middle Ages'.
   time_period_scheme_id LONG, 
   external_scheme_term_id VARCHAR(80), -- Term identifier in the external scheme.
   FOREIGN KEY (time_period_scheme_id) REFERENCES l_scheme
);

CREATE TABLE g_collection (
   collection_id LONG NOT NULL PRIMARY KEY, -- A machine-generated identifier assigned to uniquely distinguish a collection.
   name VARCHAR(100) NOT NULL, -- Name of the collection.
   note VARCHAR(255) -- Note about the collection.
);

CREATE TABLE g_time_date_range (
   time_period_id LONG NOT NULL PRIMARY KEY,
   date_range_begin DATE,
   date_range_end DATE,
   date_range_note VARCHAR(255),
   date_coding_scheme_id LONG NOT NULL, 
   FOREIGN KEY (time_period_id) REFERENCES g_time_period,
   FOREIGN KEY (date_coding_scheme_id) REFERENCES l_scheme
);

CREATE TABLE g_time_period_to_period_name (
   time_period_id LONG NOT NULL,  
   time_period_name_id LONG NOT NULL,
   PRIMARY KEY (time_period_id,time_period_name_id),
   FOREIGN KEY (time_period_id) REFERENCES g_time_period,
   FOREIGN KEY (time_period_name_id) REFERENCES l_time_period_name
);

CREATE TABLE g_feature (
   feature_id LONG NOT NULL PRIMARY KEY, -- A machine-generated identifier assigned to uniquely distinguish a feature.
   collection_id LONG, -- A machine-generated identifier assigned to uniquely distinguish a collection.
   is_complete BOOLEAN, -- Whether this feature data is complete.
   time_period_id LONG NOT NULL, 
   entry_note VARCHAR(80), -- Note explaining something about this gazetteer entry.
   entry_date DATE NOT NULL, -- Date that the entry was first added to the gazetteer.
   modification_date DATE NOT NULL, -- Date that the entry was last modified.
   FOREIGN KEY (collection_id) REFERENCES g_collection,
   FOREIGN KEY (time_period_id) REFERENCES g_time_period
);

CREATE TABLE g_address (
   address_id LONG NOT NULL PRIMARY KEY,
   feature_id LONG NOT NULL, -- A machine-generated identifier assigned to uniquely distinguish a feature.
   street_address VARCHAR(80) NOT NULL, -- Street address for the physical location.
   city VARCHAR(80) NOT NULL, -- City name for the address.
   state_province VARCHAR(80) NOT NULL, -- State or province name for the address.
   postal_code VARCHAR(20) NOT NULL, -- Postal code for the address.
   country VARCHAR(20) NOT NULL, -- Country for the address.
   FOREIGN KEY (feature_id) REFERENCES g_feature
);

CREATE TABLE g_begin_end_date (
   begin_end_date_id LONG NOT NULL PRIMARY KEY,
   time_period_id LONG NOT NULL, -- time period this detail is associated to
   calendar_system VARCHAR(20) NOT NULL, -- calendar_system 
   date_coding_scheme_id LONG NOT NULL, 
   begin_date DATE, -- Beginning date for the date range, expressed according to the ISO 8601-2000 standard.
   begin_date_confidence_value FLOAT, -- A single value, in terms of years, indicating of the range of values for the date. For example, ""5"" indicates that the date value could be 5 years earlier to 5 years later."
   begin_date_confidence_note VARCHAR(80), -- A statement of the confidence in the date. For example, citing contradictory or incomplete documentation.
   begin_date_note VARCHAR(80), -- Any explanation of the date given or additional information, such as date expression according to a different standard.
   end_date DATE, -- Ending date for the time period.
   end_date_confidence_value FLOAT, -- A single value, in terms of years, indicating of the range of values for the date. For example, ""5"" indicates that the date value could be 5 years earlier to 5 years later."
   end_date_confidence_note VARCHAR(80), -- A statement of the confidence in the date. For example, citing contradictory or incomplete documentation.
   end_date_note VARCHAR(80), -- Any explanation of the date given or additional information, such as date expression according to a different standard.
   FOREIGN KEY (time_period_id) REFERENCES g_time_period,
   FOREIGN KEY (date_coding_scheme_id) REFERENCES l_scheme
);

CREATE TABLE g_classification (
   classification_id LONG NOT NULL PRIMARY KEY,
   feature_id LONG NOT NULL, -- A machine-generated identifier assigned to uniquely distinguish a feature.
   classification_term_id LONG NOT NULL,
   primary_display BOOLEAN NOT NULL, -- Whether this is the primary display for this class term.
   time_period_id LONG NOT NULL, -- Identifier to time period informationa.  Indicating the current, former, or proposed status of the type associated with the feature, plus beginning and ending dates for the type designation for this feature or the name of the time period with which it is associated.
   time_period_note VARCHAR(255),
   FOREIGN KEY (feature_id) REFERENCES g_feature,
   FOREIGN KEY (classification_term_id) REFERENCES l_scheme_term,
   FOREIGN KEY (time_period_id) REFERENCES g_time_period
);

CREATE TABLE g_description (
   description_id LONG NOT NULL PRIMARY KEY,
   feature_id LONG NOT NULL, -- A machine-generated identifier assigned to uniquely distinguish a feature.
   description_type_scheme_id LONG,
   description_type_term VARCHAR(255), -- Category term describing the type of description. For example, history, industry, climate, culture, terrain, etc.
   external_scheme_term_id VARCHAR(80),
   short_description TEXT(2000), -- Descriptive paragraph about the place. For longer descriptions, link to an extenal file.
   FOREIGN KEY (description_type_scheme_id) REFERENCES l_scheme
);

CREATE TABLE g_encoded_date (
   encoded_date_id LONG NOT NULL PRIMARY KEY,
   time_period_id LONG NOT NULL,
   date_coding_scheme_id LONG NOT NULL,
   encoded_date_string VARCHAR(255) NOT NULL,
   FOREIGN KEY (time_period_id) REFERENCES g_time_period,
   FOREIGN KEY (date_coding_scheme_id) REFERENCES l_scheme
   
);

CREATE TABLE g_entry_source (
   entry_source_id LONG NOT NULL PRIMARY KEY,
   source_id LONG NOT NULL,
   entry_date DATE NOT NULL,
   FOREIGN KEY (source_id) REFERENCES l_source_reference
);

CREATE TABLE g_feature_code (
   feature_code_id LONG NOT NULL PRIMARY KEY,
   feature_id LONG NOT NULL, -- A machine-generated identifier assigned to uniquely distinguish a feature.
   code VARCHAR(20) NOT NULL, -- Code associated with the feature, such as a FIPS code or the identifier of the feature in another gazetteer.
   code_scheme_id LONG NOT NULL,
   FOREIGN KEY (feature_id) REFERENCES g_feature,
   FOREIGN KEY (code_scheme_id) REFERENCES l_scheme
);

CREATE TABLE g_feature_data (
   feature_data_id LONG NOT NULL PRIMARY KEY,
   feature_id LONG NOT NULL, -- A machine-generated identifier assigned to uniquely distinguish a feature.
   data_type_scheme_id LONG NOT NULL, 
   data_type_term VARCHAR(80) NOT NULL, -- Category term describing the type of data. For example: population, elevation, area, etc.
   external_scheme_term_id VARCHAR(80), -- Term identifier in the external scheme.
   data_value NUMBER NOT NULL,
   data_unit VARCHAR(20) NOT NULL, -- Unit of value, for example 'residents' or 'feet' or 'meters'.
   data_basis VARCHAR(80), -- Base reference for the data value, for example 'mean sea level'.
   data_note VARCHAR(255), -- Explanatory statement for the data.
   time_period_id LONG NOT NULL,
   time_period_note VARCHAR(255),
   FOREIGN KEY (feature_id) REFERENCES g_feature,
   FOREIGN KEY (data_type_scheme_id) REFERENCES l_scheme,
   FOREIGN KEY (time_period_id) REFERENCES g_time_period
);

CREATE TABLE g_feature_link (
   feature_link_id LONG NOT NULL PRIMARY KEY,
   feature_id LONG NOT NULL, -- A machine-generated identifier assigned to uniquely distinguish a feature.
   link_description VARCHAR(80) NOT NULL, -- Title or other brief identification of the linked site.
   feature_link_scheme_id LONG, 
   feature_link_type_term VARCHAR(255),
   external_scheme_term_id VARCHAR(80), -- Term identifier in the external scheme.
   language_id LONG NOT NULL,
   link_url URI(50), -- Web address of the linked object. 
   FOREIGN KEY (feature_id) REFERENCES g_feature,
   FOREIGN KEY (feature_link_scheme_id) REFERENCES l_scheme,
   FOREIGN KEY (language_id) REFERENCES l_language
);

CREATE TABLE g_feature_name (
   feature_name_id LONG NOT NULL PRIMARY KEY,
   feature_id LONG NOT NULL, -- A machine-generated identifier assigned to uniquely distinguish a feature.
   primary_display BOOLEAN NOT NULL, -- Whether this is the name used by the gazetteer as the primary display name. One and only one name must be flagged as the primary display name in a particular gazetteer.
   name VARCHAR(255) NOT NULL, -- Name for the feature. The name is in natural order and is not modified by a parent entity.
   etymology VARCHAR(80), -- Derivation of the name.
   language_id LONG, 
   transliteration_scheme_id,
   confidence_note VARCHAR(80), -- Expression of confidence associated with this form of the name. For example, citing that the name was taken from an archeological source that could only be partial read.
   FOREIGN KEY (feature_id) REFERENCES g_feature,
   FOREIGN KEY (transliteration_scheme_id) REFERENCES l_scheme,
   FOREIGN KEY (language_id) REFERENCES l_language
);

CREATE TABLE g_location (
   location_id LONG NOT NULL PRIMARY KEY,
   feature_id LONG NOT NULL, -- A machine-generated identifier assigned to uniquely distinguish a feature.
   planet VARCHAR(20) NOT NULL,
   bounding_box_geodetic VARCHAR(20),
   west_coordinate FLOAT NOT NULL, -- Longitude value for the west edge of the location in decimal degrees.  Negative values are used for coordinates west of the prime meridian.
   east_coordinate FLOAT NOT NULL, -- Longitude value for the east edge of the location in decimal degrees.  Negative values are used for coordinates west of the prime meridian.
   south_coordinate FLOAT NOT NULL, -- Latitude value for the south edge of the location in decimal degrees.  Negative values are used for south of the equator.
   north_coordinate FLOAT NOT NULL, -- Latitude value for the north edge of the location in decimal degrees.  Negative values are used for coordinates south of the equator.
   deleted_column1 LONG,
   bounding_box_method VARCHAR(80) NOT NULL, -- Documentation about the process used to generate the bounding box.
   bounding_box_source_type VARCHAR(20) NOT NULL, -- Which geometries were used to generate the bounding box. 'Primary' means that the primary geometry was used. 'TimeSpecific' means that the geometry for a particular time period was used. In this case, the time period is specified in the 'timePer' element. 'All' means that all geometries were used.
   FOREIGN KEY (feature_id) REFERENCES g_feature
);

CREATE TABLE g_location_geometry (
   location_geometry_id LONG NOT NULL PRIMARY KEY,
   location_id LONG NOT NULL,
   primary_geometry BOOLEAN NOT NULL,
   local_geometry BOOLEAN NOT NULL, -- Whether the geometry is represents as a reference URL or a set of coordinates.
   geometry_coding_scheme_id LONG NOT NULL,
   encoded_geometry TEXT(32000),
   geometry_reference_url URI(500), -- URL reference to a file that contains the coordinate points or other representation of geographic location, such as a grid representation. File needs to be self-explanatory.
   time_period_id LONG NOT NULL,
   measurement_begin_date DATE, -- Documentation about when the footprint was measured. This is the beginning date.
   measurement_end_date DATE, -- Documentation about when the footprint was measured. This is the ending date.
   measurement_method VARCHAR(255), -- Method used to measure the footprint, e.g., GPS, derived from map (printed) or map data, image analysis, etc.
   geometry_confidence_value FLOAT, -- A positive value, expressed in decimal degrees, setting the range of values (+ and -) that the geometry values represent. For example, ""1"" would mean that a 1 degree buffer around the coordinates is implied.
   geometry_confidence_note VARCHAR(255), -- A statement of the confidence in the location. For example, citing contradictory or scanty evidence.
   time_period_note VARCHAR(255),
   FOREIGN KEY (location_id) REFERENCES g_location,
   FOREIGN KEY (geometry_coding_scheme_id) REFERENCES l_scheme,
   FOREIGN KEY (time_period_id) REFERENCES g_time_period  
);

CREATE TABLE g_name_abbreviation (
   feature_name_id LONG NOT NULL PRIMARY KEY,
   name_abbreviation VARCHAR(20) NOT NULL, -- Abbreviated form of the name. For example, 'CA' and 'Calif' for 'California'.
   FOREIGN KEY (feature_name_id) REFERENCES g_feature_name
);

CREATE TABLE g_name_to_link_info_reference (
   feature_name_id LONG NOT NULL,
   source_reference_id LONG NOT NULL, -- Edition or version number of the source document.
   pages VARCHAR(20),
   PRIMARY KEY (feature_name_id,source_reference_id),
   FOREIGN KEY (feature_name_id) REFERENCES g_feature_name,
   FOREIGN KEY (source_reference_id) REFERENCES l_source_reference
);

CREATE TABLE g_name_to_time_period (
   feature_name_id LONG NOT NULL,
   time_period_id LONG NOT NULL,
   primary_time_period BOOLEAN NOT NULL,
   time_period_note VARCHAR(255),
   PRIMARY KEY (feature_name_id,time_period_id),
   FOREIGN KEY (feature_name_id) REFERENCES g_feature_name,
   FOREIGN KEY (time_period_id) REFERENCES g_time_period
);

CREATE TABLE g_name_toponymic_authority (
   feature_name_id LONG NOT NULL,
   toponymic_contributor_id LONG NOT NULL,
   PRIMARY KEY (feature_name_id,toponymic_contributor_id),
   FOREIGN KEY (feature_name_id) REFERENCES g_feature_name,
   FOREIGN KEY (toponymic_contributor_id) REFERENCES l_contributor
);

CREATE TABLE g_pronunciation (
   pronunciation_id LONG NOT NULL PRIMARY KEY,
   feature_name_id LONG NOT NULL,
   pronunciation_note VARCHAR(80), --Description of where this pronunciation is used (example: 'In Paris' or 'In U.S.') or source of the pronunciation.
   pronunciation_text VARCHAR(80), -- Textual description of a pronunciation of this name.
   pronunciation_text_url URI(500), -- URL for source of the pronunciation text
   pronunciation_audio_url URI(500), -- Link (URL) to an audio file or application.
   FOREIGN KEY (feature_name_id) REFERENCES g_feature_name
);

CREATE TABLE g_related_feature (
   related_feature_id LONG NOT NULL PRIMARY KEY,
   feature_id LONG NOT NULL, -- A machine-generated identifier assigned to uniquely distinguish a feature.
   related_name VARCHAR(100) NOT NULL, -- Name by which the related feature is known.
   related_feature_feature_id LONG, -- If the related feature has a record in the gazetteer, this is where its unique identifier is recorded.
   time_period_id LONG NOT NULL,
   related_type_term_id LONG NOT NULL,
   time_period_note VARCHAR(255),
   FOREIGN KEY (feature_id) REFERENCES g_feature,
   FOREIGN KEY (related_feature_feature_id) REFERENCES g_feature,
   FOREIGN KEY (time_period_id) REFERENCES g_time_period,
   FOREIGN KEY (related_type_term_id) REFERENCES l_scheme_term
);

CREATE TABLE g_source (
   source_id LONG NOT NULL PRIMARY KEY,
   source_mnemonic VARCHAR(80) NOT NULL, -- Unique code for the contributor-source combination, in the form of ADL-1 or USGS-FGDC-1.
   contributor_id LONG NOT NULL,
   source_reference_id LONG NOT NULL, -- Edition or version number of the source document.
   FOREIGN KEY (contributor_id) REFERENCES l_contributor,
   FOREIGN KEY (source_reference_id) REFERENCES l_source_reference
);

CREATE TABLE g_supplemental_note (
   feature_id LONG NOT NULL PRIMARY KEY,
   supplemental_note TEXT(1000), -- Note explaining an unusual circumstance with the gazetteer entry.
   FOREIGN KEY (feature_id) REFERENCES g_feature
);

CREATE TABLE s_address (
   address_id LONG NOT NULL PRIMARY KEY,
   entry_source_id LONG NOT NULL,
   FOREIGN KEY (address_id) REFERENCES g_address,   
   FOREIGN KEY (entry_source_id) REFERENCES g_entry_source
);

CREATE TABLE s_classification (
   classification_id LONG NOT NULL PRIMARY KEY,
   classification_term_id LONG NOT NULL,
   time_period_id LONG NOT NULL,
   entry_source_id LONG NOT NULL,
   FOREIGN KEY (classification_id) REFERENCES g_classification,
   FOREIGN KEY (classification_term_id) REFERENCES g_entry_source,
   FOREIGN KEY (time_period_id) REFERENCES g_entry_source,
   FOREIGN KEY (entry_source_id) REFERENCES g_entry_source
);

CREATE TABLE s_description (
   description_id LONG NOT NULL PRIMARY KEY,
   entry_source_id LONG NOT NULL,
   FOREIGN KEY (description_id) REFERENCES g_description,
   FOREIGN KEY (entry_source_id) REFERENCES g_entry_source
);

CREATE TABLE s_feature (
   feature_id LONG NOT NULL PRIMARY KEY,
   time_period_id LONG NOT NULL,
   entry_source_id LONG NOT NULL,
   FOREIGN KEY (feature_id) REFERENCES g_feature,
   FOREIGN KEY (time_period_id) REFERENCES g_time_period,
   FOREIGN KEY (entry_source_id) REFERENCES g_entry_source
);

CREATE TABLE s_feature_code (
   feature_code_id LONG NOT NULL PRIMARY KEY,
   entry_source_id LONG NOT NULL,
   FOREIGN KEY (feature_code_id) REFERENCES g_feature_code,
   FOREIGN KEY (entry_source_id) REFERENCES g_entry_source
);

CREATE TABLE s_feature_data (
   feature_data_id LONG NOT NULL PRIMARY KEY,
   entry_source_id LONG NOT NULL,
   FOREIGN KEY (feature_data_id) REFERENCES g_feature_data,
   FOREIGN KEY (entry_source_id) REFERENCES g_entry_source
);

CREATE TABLE s_feature_link (
   feature_link_id LONG NOT NULL PRIMARY KEY,
   entry_source_id LONG NOT NULL,
   FOREIGN KEY (feature_link_id) REFERENCES g_feature_link,
   FOREIGN KEY (entry_source_id) REFERENCES g_entry_source
);

CREATE TABLE s_location (
   location_id LONG NOT NULL PRIMARY KEY,
   bounding_box_source_entry_id LONG NOT NULL,
   FOREIGN KEY (location_id) REFERENCES g_location,
   FOREIGN KEY (bounding_box_source_entry_id) REFERENCES g_entry_source 
);

CREATE TABLE s_feature_name (
   feature_name_id LONG NOT NULL PRIMARY KEY,
   name LONG NOT NULL,
   etymology LONG,
   language_id LONG,
   transliteration_scheme_id LONG,
   confidence_note LONG,
   FOREIGN KEY (feature_name_id) REFERENCES g_feature_name,
   FOREIGN KEY (name) REFERENCES g_entry_source,
   FOREIGN KEY (etymology) REFERENCES g_feature_name,
   FOREIGN KEY (language_id) REFERENCES g_entry_source,
   FOREIGN KEY (transliteration_scheme_id) REFERENCES g_feature_name,
   FOREIGN KEY (confidence_note) REFERENCES g_entry_source
);

CREATE TABLE s_location_geometry (
   location_geometry_id LONG NOT NULL PRIMARY KEY,
   time_period_id LONG NOT NULL,
   entry_source_id LONG NOT NULL, 
   FOREIGN KEY (location_geometry_id) REFERENCES g_location_geometry,
   FOREIGN KEY (time_period_id) REFERENCES g_time_period,
   FOREIGN KEY (entry_source_id) REFERENCES g_entry_source
);

CREATE TABLE s_name_to_link_info_reference (
   feature_name_id LONG NOT NULL,
   source_reference_id VARCHAR(80) NOT NULL,
   entry_source_id LONG NOT NULL,
   PRIMARY KEY (feature_name_id,source_reference_id),
   FOREIGN KEY (feature_name_id) REFERENCES g_feature_name,
   FOREIGN KEY (source_reference_id) REFERENCES g_source, 
   FOREIGN KEY (entry_source_id) REFERENCES g_entry_source
);

CREATE TABLE s_name_to_time_period (
   feature_name_id LONG NOT NULL,
   time_period_id LONG NOT NULL,
   entry_source_id LONG NOT NULL,
   PRIMARY KEY (feature_name_id,time_period_id),
   FOREIGN KEY (feature_name_id) REFERENCES g_feature_name,  
   FOREIGN KEY (time_period_id) REFERENCES g_time_period,  
   FOREIGN KEY (entry_source_id) REFERENCES g_entry_source
);

CREATE TABLE s_name_toponymic_authority (
   feature_name_id LONG NOT NULL,
   toponymic_contributor_id LONG NOT NULL,
   entry_source_id LONG NOT NULL,
   PRIMARY KEY (feature_name_id,toponymic_contributor_id),
   FOREIGN KEY (feature_name_id) REFERENCES g_feature_name,
   FOREIGN KEY (toponymic_contributor_id) REFERENCES l_contributor,
   FOREIGN KEY (entry_source_id) REFERENCES g_entry_source
);

CREATE TABLE s_pronunciation (
   pronunciation_id LONG NOT NULL PRIMARY KEY,
   entry_source_id LONG NOT NULL,
   FOREIGN KEY (pronunciation_id) REFERENCES g_pronunciation,
   FOREIGN KEY (entry_source_id) REFERENCES g_entry_source
);

CREATE TABLE s_related_feature (
   related_feature_id LONG NOT NULL PRIMARY KEY,
   time_period_id LONG NOT NULL,
   entry_source_id LONG NOT NULL,
   FOREIGN KEY (related_feature_id) REFERENCES g_related_feature,   
   FOREIGN KEY (time_period_id) REFERENCES g_time_period,   
   FOREIGN KEY (entry_source_id) REFERENCES g_entry_source
);

CREATE TABLE s_supplemental_note (
   feature_id LONG NOT NULL PRIMARY KEY,
   entry_source_id LONG NOT NULL,
   FOREIGN KEY (feature_id) REFERENCES g_feature,
   FOREIGN KEY (entry_source_id) REFERENCES g_entry_source
);

CREATE TABLE s_time_period (
   time_period_id LONG NOT NULL PRIMARY KEY,
   entry_source_id LONG NOT NULL,
   FOREIGN KEY (time_period_id) REFERENCES g_time_period,
   FOREIGN KEY (entry_source_id) REFERENCES g_entry_source
);

INSERT INTO l_scheme VALUES (0,'UNDEFINED SCHEME',NULL,'1.0',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'GLOBAL',0);
INSERT INTO l_scheme VALUES (1,'UNDEFINED SCHEME FOR LANGUAGE',NULL,'1.0',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'LANGUAGE',0);
INSERT INTO l_scheme VALUES (2,'UNDEFINED SCHEME FOR FEATURE TYPE',NULL,'1.0',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'FEATURE TYPE',0);
INSERT INTO l_scheme VALUES (3,'UNDEFINED SCHEME FOR STATUS',NULL,'1.0',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'STATUS',0);
INSERT INTO l_scheme VALUES (4,'UNDEFINED SCHEME FOR TIME PERIOD',NULL,'1.0',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'TIME PERIOD',0);
INSERT INTO l_scheme VALUES (5,'UNDEFINED SCHEME FOR DATE CODING',NULL,'1.0',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'DATE CODING',0);
INSERT INTO l_scheme VALUES (6,'UNDEFINED SCHEME FOR DESCRIPTION TYPE',NULL,'1.0',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'DESCRIPTION TYPE',0);
INSERT INTO l_scheme VALUES (7,'UNDEFINED SCHEME FOR DATA/UNIT TYPE',NULL,'1.0',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'DATA/UNIT',0);
INSERT INTO l_scheme VALUES (8,'UNDEFINED SCHEME FOR FEATURE LINK',NULL,'1.0',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'FEATURE LINK',0);
INSERT INTO l_scheme VALUES (9,'UNDEFINED SCHEME FOR TRANSLITERATION',NULL,'1.0',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'TRANSLITERATION',0);
INSERT INTO l_scheme VALUES (10,'UNDEFINED SCHEME FOR GEOMETRY CODING',NULL,'1.0',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'GEOMETRY CODING',0);
INSERT INTO l_scheme VALUES (11,'ISO 639-2 Language Code List','ISO 639-2','1.0','http://www.loc.gov/standards/iso639-2/',NULL,NULL,NULL,NULL,NULL,'Codes for the representation of names of languages-- Part 2: alpha-3','LANGUAGE',0);
INSERT INTO l_scheme VALUES (12,'Alexandria Digital Library Feature Type Thesaurus','ADL-FTT','July 3, 2002','http://legacy.alexandria.ucsb.edu/gazetteer/FeatureTypes/ver070302/index.htm',NULL,NULL,NULL,NULL,NULL,NULL,'FEATURE TYPE',0);

INSERT INTO l_language VALUES (1,'AAR',11);
INSERT INTO l_language VALUES (2,'ABK',11);
INSERT INTO l_language VALUES (3,'ACE',11);
INSERT INTO l_language VALUES (4,'ACH',11);
INSERT INTO l_language VALUES (5,'ADA',11);
INSERT INTO l_language VALUES (6,'ADY',11);
INSERT INTO l_language VALUES (7,'AFA',11);
INSERT INTO l_language VALUES (8,'AFH',11);
INSERT INTO l_language VALUES (9,'AFR',11);
INSERT INTO l_language VALUES (10,'AIN',11);
INSERT INTO l_language VALUES (11,'AKA',11);
INSERT INTO l_language VALUES (12,'AKK',11);
INSERT INTO l_language VALUES (13,'ALB',11);
INSERT INTO l_language VALUES (14,'ALE',11);
INSERT INTO l_language VALUES (15,'ALG',11);
INSERT INTO l_language VALUES (16,'ALT',11);
INSERT INTO l_language VALUES (17,'AMH',11);
INSERT INTO l_language VALUES (18,'ANG',11);
INSERT INTO l_language VALUES (19,'ANP',11);
INSERT INTO l_language VALUES (20,'APA',11);
INSERT INTO l_language VALUES (21,'ARA',11);
INSERT INTO l_language VALUES (22,'ARC',11);
INSERT INTO l_language VALUES (23,'ARG',11);
INSERT INTO l_language VALUES (24,'ARM',11);
INSERT INTO l_language VALUES (25,'ARN',11);
INSERT INTO l_language VALUES (26,'ARP',11);
INSERT INTO l_language VALUES (27,'ART',11);
INSERT INTO l_language VALUES (28,'ARW',11);
INSERT INTO l_language VALUES (29,'ASM',11);
INSERT INTO l_language VALUES (30,'AST',11);
INSERT INTO l_language VALUES (31,'ATH',11);
INSERT INTO l_language VALUES (32,'AUS',11);
INSERT INTO l_language VALUES (33,'AVA',11);
INSERT INTO l_language VALUES (34,'AVE',11);
INSERT INTO l_language VALUES (35,'AWA',11);
INSERT INTO l_language VALUES (36,'AYM',11);
INSERT INTO l_language VALUES (37,'AZE',11);
INSERT INTO l_language VALUES (38,'BAD',11);
INSERT INTO l_language VALUES (39,'BAI',11);
INSERT INTO l_language VALUES (40,'BAK',11);
INSERT INTO l_language VALUES (41,'BAL',11);
INSERT INTO l_language VALUES (42,'BAM',11);
INSERT INTO l_language VALUES (43,'BAN',11);
INSERT INTO l_language VALUES (44,'BAQ',11);
INSERT INTO l_language VALUES (45,'BAS',11);
INSERT INTO l_language VALUES (46,'BAT',11);
INSERT INTO l_language VALUES (47,'BEJ',11);
INSERT INTO l_language VALUES (48,'BEL',11);
INSERT INTO l_language VALUES (49,'BEM',11);
INSERT INTO l_language VALUES (50,'BEN',11);
INSERT INTO l_language VALUES (51,'BER',11);
INSERT INTO l_language VALUES (52,'BHO',11);
INSERT INTO l_language VALUES (53,'BIH',11);
INSERT INTO l_language VALUES (54,'BIK',11);
INSERT INTO l_language VALUES (55,'BIN',11);
INSERT INTO l_language VALUES (56,'BIS',11);
INSERT INTO l_language VALUES (57,'BLA',11);
INSERT INTO l_language VALUES (58,'BNT',11);
INSERT INTO l_language VALUES (59,'BOD',11);
INSERT INTO l_language VALUES (60,'BOS',11);
INSERT INTO l_language VALUES (61,'BRA',11);
INSERT INTO l_language VALUES (62,'BRE',11);
INSERT INTO l_language VALUES (63,'BTK',11);
INSERT INTO l_language VALUES (64,'BUA',11);
INSERT INTO l_language VALUES (65,'BUG',11);
INSERT INTO l_language VALUES (66,'BUL',11);
INSERT INTO l_language VALUES (67,'BUR',11);
INSERT INTO l_language VALUES (68,'BYN',11);
INSERT INTO l_language VALUES (69,'CAD',11);
INSERT INTO l_language VALUES (70,'CAI',11);
INSERT INTO l_language VALUES (71,'CAR',11);
INSERT INTO l_language VALUES (72,'CAT',11);
INSERT INTO l_language VALUES (73,'CAU',11);
INSERT INTO l_language VALUES (74,'CEB',11);
INSERT INTO l_language VALUES (75,'CEL',11);
INSERT INTO l_language VALUES (76,'CES',11);
INSERT INTO l_language VALUES (77,'CHA',11);
INSERT INTO l_language VALUES (78,'CHB',11);
INSERT INTO l_language VALUES (79,'CHE',11);
INSERT INTO l_language VALUES (80,'CHG',11);
INSERT INTO l_language VALUES (81,'CHI',11);
INSERT INTO l_language VALUES (82,'CHK',11);
INSERT INTO l_language VALUES (83,'CHM',11);
INSERT INTO l_language VALUES (84,'CHN',11);
INSERT INTO l_language VALUES (85,'CHO',11);
INSERT INTO l_language VALUES (86,'CHP',11);
INSERT INTO l_language VALUES (87,'CHR',11);
INSERT INTO l_language VALUES (88,'CHU',11);
INSERT INTO l_language VALUES (89,'CHV',11);
INSERT INTO l_language VALUES (90,'CHY',11);
INSERT INTO l_language VALUES (91,'CMC',11);
INSERT INTO l_language VALUES (92,'CNR',11);
INSERT INTO l_language VALUES (93,'COP',11);
INSERT INTO l_language VALUES (94,'COR',11);
INSERT INTO l_language VALUES (95,'COS',11);
INSERT INTO l_language VALUES (96,'CPE',11);
INSERT INTO l_language VALUES (97,'CPF',11);
INSERT INTO l_language VALUES (98,'CPP',11);
INSERT INTO l_language VALUES (99,'CRE',11);
INSERT INTO l_language VALUES (100,'CRH',11);
INSERT INTO l_language VALUES (101,'CRP',11);
INSERT INTO l_language VALUES (102,'CSB',11);
INSERT INTO l_language VALUES (103,'CUS',11);
INSERT INTO l_language VALUES (104,'CYM',11);
INSERT INTO l_language VALUES (105,'CZE',11);
INSERT INTO l_language VALUES (106,'DAK',11);
INSERT INTO l_language VALUES (107,'DAN',11);
INSERT INTO l_language VALUES (108,'DAR',11);
INSERT INTO l_language VALUES (109,'DAY',11);
INSERT INTO l_language VALUES (110,'DEL',11);
INSERT INTO l_language VALUES (111,'DEN',11);
INSERT INTO l_language VALUES (112,'DEU',11);
INSERT INTO l_language VALUES (113,'DGR',11);
INSERT INTO l_language VALUES (114,'DIN',11);
INSERT INTO l_language VALUES (115,'DIV',11);
INSERT INTO l_language VALUES (116,'DOI',11);
INSERT INTO l_language VALUES (117,'DRA',11);
INSERT INTO l_language VALUES (118,'DSB',11);
INSERT INTO l_language VALUES (119,'DUA',11);
INSERT INTO l_language VALUES (120,'DUM',11);
INSERT INTO l_language VALUES (121,'DUT',11);
INSERT INTO l_language VALUES (122,'DYU',11);
INSERT INTO l_language VALUES (123,'DZO',11);
INSERT INTO l_language VALUES (124,'EFI',11);
INSERT INTO l_language VALUES (125,'EGY',11);
INSERT INTO l_language VALUES (126,'EKA',11);
INSERT INTO l_language VALUES (127,'ELL',11);
INSERT INTO l_language VALUES (128,'ELX',11);
INSERT INTO l_language VALUES (129,'ENG',11);
INSERT INTO l_language VALUES (130,'ENM',11);
INSERT INTO l_language VALUES (131,'EPO',11);
INSERT INTO l_language VALUES (132,'EST',11);
INSERT INTO l_language VALUES (133,'EUS',11);
INSERT INTO l_language VALUES (134,'EWE',11);
INSERT INTO l_language VALUES (135,'EWO',11);
INSERT INTO l_language VALUES (136,'FAN',11);
INSERT INTO l_language VALUES (137,'FAO',11);
INSERT INTO l_language VALUES (138,'FAS',11);
INSERT INTO l_language VALUES (139,'FAT',11);
INSERT INTO l_language VALUES (140,'FIJ',11);
INSERT INTO l_language VALUES (141,'FIL',11);
INSERT INTO l_language VALUES (142,'FIN',11);
INSERT INTO l_language VALUES (143,'FIU',11);
INSERT INTO l_language VALUES (144,'FON',11);
INSERT INTO l_language VALUES (145,'FRA',11);
INSERT INTO l_language VALUES (146,'FRE',11);
INSERT INTO l_language VALUES (147,'FRM',11);
INSERT INTO l_language VALUES (148,'FRO',11);
INSERT INTO l_language VALUES (149,'FRR',11);
INSERT INTO l_language VALUES (150,'FRS',11);
INSERT INTO l_language VALUES (151,'FRY',11);
INSERT INTO l_language VALUES (152,'FUL',11);
INSERT INTO l_language VALUES (153,'FUR',11);
INSERT INTO l_language VALUES (154,'GAA',11);
INSERT INTO l_language VALUES (155,'GAY',11);
INSERT INTO l_language VALUES (156,'GBA',11);
INSERT INTO l_language VALUES (157,'GEM',11);
INSERT INTO l_language VALUES (158,'GEO',11);
INSERT INTO l_language VALUES (159,'GER',11);
INSERT INTO l_language VALUES (160,'GEZ',11);
INSERT INTO l_language VALUES (161,'GIL',11);
INSERT INTO l_language VALUES (162,'GLA',11);
INSERT INTO l_language VALUES (163,'GLE',11);
INSERT INTO l_language VALUES (164,'GLG',11);
INSERT INTO l_language VALUES (165,'GLV',11);
INSERT INTO l_language VALUES (166,'GMH',11);
INSERT INTO l_language VALUES (167,'GOH',11);
INSERT INTO l_language VALUES (168,'GON',11);
INSERT INTO l_language VALUES (169,'GOR',11);
INSERT INTO l_language VALUES (170,'GOT',11);
INSERT INTO l_language VALUES (171,'GRB',11);
INSERT INTO l_language VALUES (172,'GRC',11);
INSERT INTO l_language VALUES (173,'GRE',11);
INSERT INTO l_language VALUES (174,'GRN',11);
INSERT INTO l_language VALUES (175,'GSW',11);
INSERT INTO l_language VALUES (176,'GUJ',11);
INSERT INTO l_language VALUES (177,'GWI',11);
INSERT INTO l_language VALUES (178,'HAI',11);
INSERT INTO l_language VALUES (179,'HAT',11);
INSERT INTO l_language VALUES (180,'HAU',11);
INSERT INTO l_language VALUES (181,'HAW',11);
INSERT INTO l_language VALUES (182,'HEB',11);
INSERT INTO l_language VALUES (183,'HER',11);
INSERT INTO l_language VALUES (184,'HIL',11);
INSERT INTO l_language VALUES (185,'HIM',11);
INSERT INTO l_language VALUES (186,'HIN',11);
INSERT INTO l_language VALUES (187,'HIT',11);
INSERT INTO l_language VALUES (188,'HMN',11);
INSERT INTO l_language VALUES (189,'HMO',11);
INSERT INTO l_language VALUES (190,'HRV',11);
INSERT INTO l_language VALUES (191,'HSB',11);
INSERT INTO l_language VALUES (192,'HUN',11);
INSERT INTO l_language VALUES (193,'HUP',11);
INSERT INTO l_language VALUES (194,'HYE',11);
INSERT INTO l_language VALUES (195,'IBA',11);
INSERT INTO l_language VALUES (196,'IBO',11);
INSERT INTO l_language VALUES (197,'ICE',11);
INSERT INTO l_language VALUES (198,'IDO',11);
INSERT INTO l_language VALUES (199,'III',11);
INSERT INTO l_language VALUES (200,'IJO',11);
INSERT INTO l_language VALUES (201,'IKU',11);
INSERT INTO l_language VALUES (202,'ILE',11);
INSERT INTO l_language VALUES (203,'ILO',11);
INSERT INTO l_language VALUES (204,'INA',11);
INSERT INTO l_language VALUES (205,'INC',11);
INSERT INTO l_language VALUES (206,'IND',11);
INSERT INTO l_language VALUES (207,'INE',11);
INSERT INTO l_language VALUES (208,'INH',11);
INSERT INTO l_language VALUES (209,'IPK',11);
INSERT INTO l_language VALUES (210,'IRA',11);
INSERT INTO l_language VALUES (211,'IRO',11);
INSERT INTO l_language VALUES (212,'ISL',11);
INSERT INTO l_language VALUES (213,'ITA',11);
INSERT INTO l_language VALUES (214,'JAV',11);
INSERT INTO l_language VALUES (215,'JBO',11);
INSERT INTO l_language VALUES (216,'JPN',11);
INSERT INTO l_language VALUES (217,'JPR',11);
INSERT INTO l_language VALUES (218,'JRB',11);
INSERT INTO l_language VALUES (219,'KAA',11);
INSERT INTO l_language VALUES (220,'KAB',11);
INSERT INTO l_language VALUES (221,'KAC',11);
INSERT INTO l_language VALUES (222,'KAL',11);
INSERT INTO l_language VALUES (223,'KAM',11);
INSERT INTO l_language VALUES (224,'KAN',11);
INSERT INTO l_language VALUES (225,'KAR',11);
INSERT INTO l_language VALUES (226,'KAS',11);
INSERT INTO l_language VALUES (227,'KAT',11);
INSERT INTO l_language VALUES (228,'KAU',11);
INSERT INTO l_language VALUES (229,'KAW',11);
INSERT INTO l_language VALUES (230,'KAZ',11);
INSERT INTO l_language VALUES (231,'KBD',11);
INSERT INTO l_language VALUES (232,'KHA',11);
INSERT INTO l_language VALUES (233,'KHI',11);
INSERT INTO l_language VALUES (234,'KHM',11);
INSERT INTO l_language VALUES (235,'KHO',11);
INSERT INTO l_language VALUES (236,'KIK',11);
INSERT INTO l_language VALUES (237,'KIN',11);
INSERT INTO l_language VALUES (238,'KIR',11);
INSERT INTO l_language VALUES (239,'KMB',11);
INSERT INTO l_language VALUES (240,'KOK',11);
INSERT INTO l_language VALUES (241,'KOM',11);
INSERT INTO l_language VALUES (242,'KON',11);
INSERT INTO l_language VALUES (243,'KOR',11);
INSERT INTO l_language VALUES (244,'KOS',11);
INSERT INTO l_language VALUES (245,'KPE',11);
INSERT INTO l_language VALUES (246,'KRC',11);
INSERT INTO l_language VALUES (247,'KRL',11);
INSERT INTO l_language VALUES (248,'KRO',11);
INSERT INTO l_language VALUES (249,'KRU',11);
INSERT INTO l_language VALUES (250,'KUA',11);
INSERT INTO l_language VALUES (251,'KUM',11);
INSERT INTO l_language VALUES (252,'KUR',11);
INSERT INTO l_language VALUES (253,'KUT',11);
INSERT INTO l_language VALUES (254,'LAD',11);
INSERT INTO l_language VALUES (255,'LAH',11);
INSERT INTO l_language VALUES (256,'LAM',11);
INSERT INTO l_language VALUES (257,'LAO',11);
INSERT INTO l_language VALUES (258,'LAT',11);
INSERT INTO l_language VALUES (259,'LAV',11);
INSERT INTO l_language VALUES (260,'LEZ',11);
INSERT INTO l_language VALUES (261,'LIM',11);
INSERT INTO l_language VALUES (262,'LIN',11);
INSERT INTO l_language VALUES (263,'LIT',11);
INSERT INTO l_language VALUES (264,'LOL',11);
INSERT INTO l_language VALUES (265,'LOZ',11);
INSERT INTO l_language VALUES (266,'LTZ',11);
INSERT INTO l_language VALUES (267,'LUA',11);
INSERT INTO l_language VALUES (268,'LUB',11);
INSERT INTO l_language VALUES (269,'LUG',11);
INSERT INTO l_language VALUES (270,'LUI',11);
INSERT INTO l_language VALUES (271,'LUN',11);
INSERT INTO l_language VALUES (272,'LUO',11);
INSERT INTO l_language VALUES (273,'LUS',11);
INSERT INTO l_language VALUES (274,'MAC',11);
INSERT INTO l_language VALUES (275,'MAD',11);
INSERT INTO l_language VALUES (276,'MAG',11);
INSERT INTO l_language VALUES (277,'MAH',11);
INSERT INTO l_language VALUES (278,'MAI',11);
INSERT INTO l_language VALUES (279,'MAK',11);
INSERT INTO l_language VALUES (280,'MAL',11);
INSERT INTO l_language VALUES (281,'MAN',11);
INSERT INTO l_language VALUES (282,'MAO',11);
INSERT INTO l_language VALUES (283,'MAP',11);
INSERT INTO l_language VALUES (284,'MAR',11);
INSERT INTO l_language VALUES (285,'MAS',11);
INSERT INTO l_language VALUES (286,'MAY',11);
INSERT INTO l_language VALUES (287,'MDF',11);
INSERT INTO l_language VALUES (288,'MDR',11);
INSERT INTO l_language VALUES (289,'MEN',11);
INSERT INTO l_language VALUES (290,'MGA',11);
INSERT INTO l_language VALUES (291,'MIC',11);
INSERT INTO l_language VALUES (292,'MIN',11);
INSERT INTO l_language VALUES (293,'MIS',11);
INSERT INTO l_language VALUES (294,'MKD',11);
INSERT INTO l_language VALUES (295,'MKH',11);
INSERT INTO l_language VALUES (296,'MLG',11);
INSERT INTO l_language VALUES (297,'MLT',11);
INSERT INTO l_language VALUES (298,'MNC',11);
INSERT INTO l_language VALUES (299,'MNI',11);
INSERT INTO l_language VALUES (300,'MNO',11);
INSERT INTO l_language VALUES (301,'MOH',11);
INSERT INTO l_language VALUES (302,'MON',11);
INSERT INTO l_language VALUES (303,'MOS',11);
INSERT INTO l_language VALUES (304,'MRI',11);
INSERT INTO l_language VALUES (305,'MSA',11);
INSERT INTO l_language VALUES (306,'MUL',11);
INSERT INTO l_language VALUES (307,'MUN',11);
INSERT INTO l_language VALUES (308,'MUS',11);
INSERT INTO l_language VALUES (309,'MWL',11);
INSERT INTO l_language VALUES (310,'MWR',11);
INSERT INTO l_language VALUES (311,'MYA',11);
INSERT INTO l_language VALUES (312,'MYN',11);
INSERT INTO l_language VALUES (313,'MYV',11);
INSERT INTO l_language VALUES (314,'NAH',11);
INSERT INTO l_language VALUES (315,'NAI',11);
INSERT INTO l_language VALUES (316,'NAP',11);
INSERT INTO l_language VALUES (317,'NAU',11);
INSERT INTO l_language VALUES (318,'NAV',11);
INSERT INTO l_language VALUES (319,'NBL',11);
INSERT INTO l_language VALUES (320,'NDE',11);
INSERT INTO l_language VALUES (321,'NDO',11);
INSERT INTO l_language VALUES (322,'NDS',11);
INSERT INTO l_language VALUES (323,'NEP',11);
INSERT INTO l_language VALUES (324,'NEW',11);
INSERT INTO l_language VALUES (325,'NIA',11);
INSERT INTO l_language VALUES (326,'NIC',11);
INSERT INTO l_language VALUES (327,'NIU',11);
INSERT INTO l_language VALUES (328,'NLD',11);
INSERT INTO l_language VALUES (329,'NNO',11);
INSERT INTO l_language VALUES (330,'NOB',11);
INSERT INTO l_language VALUES (331,'NOG',11);
INSERT INTO l_language VALUES (332,'NON',11);
INSERT INTO l_language VALUES (333,'NOR',11);
INSERT INTO l_language VALUES (334,'NQO',11);
INSERT INTO l_language VALUES (335,'NSO',11);
INSERT INTO l_language VALUES (336,'NUB',11);
INSERT INTO l_language VALUES (337,'NWC',11);
INSERT INTO l_language VALUES (338,'NYA',11);
INSERT INTO l_language VALUES (339,'NYM',11);
INSERT INTO l_language VALUES (340,'NYN',11);
INSERT INTO l_language VALUES (341,'NYO',11);
INSERT INTO l_language VALUES (342,'NZI',11);
INSERT INTO l_language VALUES (343,'OCI',11);
INSERT INTO l_language VALUES (344,'OJI',11);
INSERT INTO l_language VALUES (345,'ORI',11);
INSERT INTO l_language VALUES (346,'ORM',11);
INSERT INTO l_language VALUES (347,'OSA',11);
INSERT INTO l_language VALUES (348,'OSS',11);
INSERT INTO l_language VALUES (349,'OTA',11);
INSERT INTO l_language VALUES (350,'OTO',11);
INSERT INTO l_language VALUES (351,'PAA',11);
INSERT INTO l_language VALUES (352,'PAG',11);
INSERT INTO l_language VALUES (353,'PAL',11);
INSERT INTO l_language VALUES (354,'PAM',11);
INSERT INTO l_language VALUES (355,'PAN',11);
INSERT INTO l_language VALUES (356,'PAP',11);
INSERT INTO l_language VALUES (357,'PAU',11);
INSERT INTO l_language VALUES (358,'PEO',11);
INSERT INTO l_language VALUES (359,'PER',11);
INSERT INTO l_language VALUES (360,'PHI',11);
INSERT INTO l_language VALUES (361,'PHN',11);
INSERT INTO l_language VALUES (362,'PLI',11);
INSERT INTO l_language VALUES (363,'POL',11);
INSERT INTO l_language VALUES (364,'PON',11);
INSERT INTO l_language VALUES (365,'POR',11);
INSERT INTO l_language VALUES (366,'PRA',11);
INSERT INTO l_language VALUES (367,'PRO',11);
INSERT INTO l_language VALUES (368,'PUS',11);
INSERT INTO l_language VALUES (369,'QAA',11);
INSERT INTO l_language VALUES (370,'QTZ',11);
INSERT INTO l_language VALUES (371,'QUE',11);
INSERT INTO l_language VALUES (372,'RAJ',11);
INSERT INTO l_language VALUES (373,'RAP',11);
INSERT INTO l_language VALUES (374,'RAR',11);
INSERT INTO l_language VALUES (375,'ROA',11);
INSERT INTO l_language VALUES (376,'ROH',11);
INSERT INTO l_language VALUES (377,'ROM',11);
INSERT INTO l_language VALUES (378,'RON',11);
INSERT INTO l_language VALUES (379,'RUM',11);
INSERT INTO l_language VALUES (380,'RUN',11);
INSERT INTO l_language VALUES (381,'RUP',11);
INSERT INTO l_language VALUES (382,'RUS',11);
INSERT INTO l_language VALUES (383,'SAD',11);
INSERT INTO l_language VALUES (384,'SAG',11);
INSERT INTO l_language VALUES (385,'SAH',11);
INSERT INTO l_language VALUES (386,'SAI',11);
INSERT INTO l_language VALUES (387,'SAL',11);
INSERT INTO l_language VALUES (388,'SAM',11);
INSERT INTO l_language VALUES (389,'SAN',11);
INSERT INTO l_language VALUES (390,'SAS',11);
INSERT INTO l_language VALUES (391,'SAT',11);
INSERT INTO l_language VALUES (392,'SCN',11);
INSERT INTO l_language VALUES (393,'SCO',11);
INSERT INTO l_language VALUES (394,'SEL',11);
INSERT INTO l_language VALUES (395,'SEM',11);
INSERT INTO l_language VALUES (396,'SGA',11);
INSERT INTO l_language VALUES (397,'SGN',11);
INSERT INTO l_language VALUES (398,'SHN',11);
INSERT INTO l_language VALUES (399,'SID',11);
INSERT INTO l_language VALUES (400,'SIN',11);
INSERT INTO l_language VALUES (401,'SIO',11);
INSERT INTO l_language VALUES (402,'SIT',11);
INSERT INTO l_language VALUES (403,'SLA',11);
INSERT INTO l_language VALUES (404,'SLK',11);
INSERT INTO l_language VALUES (405,'SLO',11);
INSERT INTO l_language VALUES (406,'SLV',11);
INSERT INTO l_language VALUES (407,'SMA',11);
INSERT INTO l_language VALUES (408,'SME',11);
INSERT INTO l_language VALUES (409,'SMI',11);
INSERT INTO l_language VALUES (410,'SMJ',11);
INSERT INTO l_language VALUES (411,'SMN',11);
INSERT INTO l_language VALUES (412,'SMO',11);
INSERT INTO l_language VALUES (413,'SMS',11);
INSERT INTO l_language VALUES (414,'SNA',11);
INSERT INTO l_language VALUES (415,'SND',11);
INSERT INTO l_language VALUES (416,'SNK',11);
INSERT INTO l_language VALUES (417,'SOG',11);
INSERT INTO l_language VALUES (418,'SOM',11);
INSERT INTO l_language VALUES (419,'SON',11);
INSERT INTO l_language VALUES (420,'SOT',11);
INSERT INTO l_language VALUES (421,'SPA',11);
INSERT INTO l_language VALUES (422,'SQI',11);
INSERT INTO l_language VALUES (423,'SRD',11);
INSERT INTO l_language VALUES (424,'SRN',11);
INSERT INTO l_language VALUES (425,'SRP',11);
INSERT INTO l_language VALUES (426,'SRR',11);
INSERT INTO l_language VALUES (427,'SSA',11);
INSERT INTO l_language VALUES (428,'SSW',11);
INSERT INTO l_language VALUES (429,'SUK',11);
INSERT INTO l_language VALUES (430,'SUN',11);
INSERT INTO l_language VALUES (431,'SUS',11);
INSERT INTO l_language VALUES (432,'SUX',11);
INSERT INTO l_language VALUES (433,'SWA',11);
INSERT INTO l_language VALUES (434,'SWE',11);
INSERT INTO l_language VALUES (435,'SYC',11);
INSERT INTO l_language VALUES (436,'SYR',11);
INSERT INTO l_language VALUES (437,'TAH',11);
INSERT INTO l_language VALUES (438,'TAI',11);
INSERT INTO l_language VALUES (439,'TAM',11);
INSERT INTO l_language VALUES (440,'TAT',11);
INSERT INTO l_language VALUES (441,'TEL',11);
INSERT INTO l_language VALUES (442,'TEM',11);
INSERT INTO l_language VALUES (443,'TER',11);
INSERT INTO l_language VALUES (444,'TET',11);
INSERT INTO l_language VALUES (445,'TGK',11);
INSERT INTO l_language VALUES (446,'TGL',11);
INSERT INTO l_language VALUES (447,'THA',11);
INSERT INTO l_language VALUES (448,'TIB',11);
INSERT INTO l_language VALUES (449,'TIG',11);
INSERT INTO l_language VALUES (450,'TIR',11);
INSERT INTO l_language VALUES (451,'TIV',11);
INSERT INTO l_language VALUES (452,'TKL',11);
INSERT INTO l_language VALUES (453,'TLH',11);
INSERT INTO l_language VALUES (454,'TLI',11);
INSERT INTO l_language VALUES (455,'TMH',11);
INSERT INTO l_language VALUES (456,'TOG',11);
INSERT INTO l_language VALUES (457,'TON',11);
INSERT INTO l_language VALUES (458,'TPI',11);
INSERT INTO l_language VALUES (459,'TSI',11);
INSERT INTO l_language VALUES (460,'TSN',11);
INSERT INTO l_language VALUES (461,'TSO',11);
INSERT INTO l_language VALUES (462,'TUK',11);
INSERT INTO l_language VALUES (463,'TUM',11);
INSERT INTO l_language VALUES (464,'TUP',11);
INSERT INTO l_language VALUES (465,'TUR',11);
INSERT INTO l_language VALUES (466,'TUT',11);
INSERT INTO l_language VALUES (467,'TVL',11);
INSERT INTO l_language VALUES (468,'TWI',11);
INSERT INTO l_language VALUES (469,'TYV',11);
INSERT INTO l_language VALUES (470,'UDM',11);
INSERT INTO l_language VALUES (471,'UGA',11);
INSERT INTO l_language VALUES (472,'UIG',11);
INSERT INTO l_language VALUES (473,'UKR',11);
INSERT INTO l_language VALUES (474,'UMB',11);
INSERT INTO l_language VALUES (475,'UND',11);
INSERT INTO l_language VALUES (476,'URD',11);
INSERT INTO l_language VALUES (477,'UZB',11);
INSERT INTO l_language VALUES (478,'VAI',11);
INSERT INTO l_language VALUES (479,'VEN',11);
INSERT INTO l_language VALUES (480,'VIE',11);
INSERT INTO l_language VALUES (481,'VOL',11);
INSERT INTO l_language VALUES (482,'VOT',11);
INSERT INTO l_language VALUES (483,'WAK',11);
INSERT INTO l_language VALUES (484,'WAL',11);
INSERT INTO l_language VALUES (485,'WAR',11);
INSERT INTO l_language VALUES (486,'WAS',11);
INSERT INTO l_language VALUES (487,'WEL',11);
INSERT INTO l_language VALUES (488,'WEN',11);
INSERT INTO l_language VALUES (489,'WLN',11);
INSERT INTO l_language VALUES (490,'WOL',11);
INSERT INTO l_language VALUES (491,'XAL',11);
INSERT INTO l_language VALUES (492,'XHO',11);
INSERT INTO l_language VALUES (493,'YAO',11);
INSERT INTO l_language VALUES (494,'YAP',11);
INSERT INTO l_language VALUES (495,'YID',11);
INSERT INTO l_language VALUES (496,'YOR',11);
INSERT INTO l_language VALUES (497,'YPK',11);
INSERT INTO l_language VALUES (498,'ZAP',11);
INSERT INTO l_language VALUES (499,'ZBL',11);
INSERT INTO l_language VALUES (500,'ZEN',11);
INSERT INTO l_language VALUES (501,'ZGH',11);
INSERT INTO l_language VALUES (502,'ZHA',11);
INSERT INTO l_language VALUES (503,'ZHO',11);
INSERT INTO l_language VALUES (504,'ZND',11);
INSERT INTO l_language VALUES (505,'ZUL',11);
INSERT INTO l_language VALUES (506,'ZUN',11);
INSERT INTO l_language VALUES (507,'ZXX',11);

INSERT INTO l_scheme_term VALUES (1,12,'abyssal features',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (2,12,'abyssal hills',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (3,12,'abyssal plains',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (4,12,'academies',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (5,12,'accelerators',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (6,12,'access areas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (7,12,'access sites',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (8,12,'adits (mine sites)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (9,12,'administrative areas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (10,12,'administrative divisions',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (11,12,'administrative facilities',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (12,12,'adminstrative facilities',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (13,12,'affluents',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (14,12,'agricultural colonies',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (15,12,'agricultural facilities',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (16,12,'agricultural regions',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (17,12,'agricultural reserves',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (18,12,'agricultural schools',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (19,12,'agricultural sites',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (20,12,'ahus',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (21,12,'air force bases',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (22,12,'air routes',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (23,12,'airbases',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (24,12,'airfields',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (25,12,'airport features',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (26,12,'airports',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (27,12,'airstrips',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (28,12,'alluvial fans',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (29,12,'amphibious bases',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (30,12,'amphitheaters',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (31,12,'amphitheatres',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (32,12,'amusement parks',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (33,12,'anabranches',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (34,12,'anchorages',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (35,12,'ancient sites',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (36,12,'anclajes',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (37,12,'animal pounds',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (38,12,'animal shelters',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (39,12,'antenna field sites',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (40,12,'anticlines',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (41,12,'apartment blocks',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (42,12,'apartment houses',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (43,12,'aprons (geological)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (44,12,'aquacultural sites',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (45,12,'aquariums',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (46,12,'aquatic centers',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (47,12,'aqueducts',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (48,12,'aquifers',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (49,12,'arboretums',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (50,12,'archaeological centers',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (51,12,'archaeological sites',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (52,12,'archeological sites',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (53,12,'arches (natural formation)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (54,12,'archipelagos',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (55,12,'archive buildings',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (56,12,'archives',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (57,12,'Arctic land',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (58,12,'arenas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (59,12,'aretes',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (60,12,'arid regions',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (61,12,'army facilities',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (62,12,'arroyos',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (63,12,'arrugados',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (64,12,'arsenals',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (65,12,'art galleries',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (66,12,'artificial islands',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (67,12,'artillery ranges',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (68,12,'asphalt lakes',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (69,12,'astronomical stations',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (70,12,'asylums',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (71,12,'athletic complexes',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (72,12,'athletic fields',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (73,12,'atolls',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (74,12,'atomic centers',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (75,12,'auditoriums',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (76,12,'backwaters',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (77,12,'badlands',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (78,12,'bahias',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (79,12,'bailing stations',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (80,12,'bajadas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (81,12,'ball parks',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (82,12,'banana plantations',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (83,12,'banks (commercial)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (84,12,'banks (hydrographic)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (85,12,'banks (seafloor)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (86,12,'barns',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (87,12,'barracks',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (88,12,'barrancas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (89,12,'barren lands',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (90,12,'barrier reefs',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (91,12,'barrios',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (92,12,'bars (physiographic)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (93,12,'baseball fields',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (94,12,'bases (military)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (95,12,'basins',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (96,12,'battle grounds',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (97,12,'battle sites',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (98,12,'battlefields',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (99,12,'bayous',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (100,12,'bays',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (101,12,'beach ridges',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (102,12,'beaches',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (103,12,'beacons',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (104,12,'beaver dams',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (105,12,'beaver ponds',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (106,12,'bench marks',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (107,12,'benches (natural)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (108,12,'benches (seafloor)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (109,12,'bends (river)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (110,12,'berms',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (111,12,'bights',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (112,12,'biogeographic regions',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (113,12,'biomes',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (114,12,'blast furnaces',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (115,12,'blowholes',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (116,12,'blowouts',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (117,12,'bluffs',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (118,12,'boardwalks',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (119,12,'boat houses',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (120,12,'boat landings',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (121,12,'boat launches',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (122,12,'boat ramps',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (123,12,'boat yards',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (124,12,'boathouses',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (125,12,'boatyards',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (126,12,'bodies of water',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (127,12,'bogs',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (128,12,'border posts',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (129,12,'borderlands (continental margins)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (130,12,'boroughs',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (131,12,'botanical gardens',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (132,12,'bottomlands',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (133,12,'boulder fields',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (134,12,'boundaries',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (135,12,'boundary markers',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (136,12,'boundary regions',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (137,12,'bowls (performance)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (138,12,'breakwaters',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (139,12,'breweries',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (140,12,'bridges',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (141,12,'brooks',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (142,12,'buffer zones',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (143,12,'buildings',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (144,12,'buoys',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (145,12,'burial caves',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (146,12,'burns (hydrographic)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (147,12,'burying grounds',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (148,12,'bushes',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (149,12,'business centers',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (150,12,'buttes',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (151,12,'cabins',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (152,12,'cableways',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (153,12,'cadastral areas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (154,12,'cairns',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (155,12,'calderas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (156,12,'campgrounds',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (157,12,'camping sites',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (158,12,'camps',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (159,12,'camps (military)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (160,12,'campuses',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (161,12,'canal bends',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (162,12,'canal tunnels',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (163,12,'canalized streams',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (164,12,'canals',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (165,12,'canneries',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (166,12,'cantons',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (167,12,'canyons',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (168,12,'capes',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (169,12,'capitals',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (170,12,'capitol buildings',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (171,12,'caravan routes',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (172,12,'carillons',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (173,12,'cascades',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (174,12,'casinos',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (175,12,'castles',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (176,12,'cataracts',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (177,12,'catchments',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (178,12,'cathedrals',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (179,12,'cattle dipping tanks',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (180,12,'causeways',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (181,12,'cave entrances',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (182,12,'caverns',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (183,12,'caves',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (184,12,'cays',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (185,12,'cement plants',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (186,12,'cemeteries',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (187,12,'census areas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (188,12,'cerros',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (189,12,'channels',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (190,12,'chapels',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (191,12,'chapparal areas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (192,12,'chart regions',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (193,12,'chasms',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (194,12,'childrens homes',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (195,12,'chotts',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (196,12,'chrome mines',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (197,12,'churches',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (198,12,'chutes (hydrographic)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (199,12,'cienagas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (200,12,'cirques',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (201,12,'cisterns',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (202,12,'cities',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (203,12,'city halls',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (204,12,'civic centers',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (205,12,'civil areas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (206,12,'civil buildings',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (207,12,'claims (land)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (208,12,'clearings',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (209,12,'clefts',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (210,12,'cliff dwellings',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (211,12,'cliffs',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (212,12,'climatic regions',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (213,12,'clinics',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (214,12,'club houses',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (215,12,'clubs (recreational)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (216,12,'coal fields',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (217,12,'coal mines',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (218,12,'coalfields',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (219,12,'coast guard stations',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (220,12,'coastal plains',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (221,12,'coastal zones',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (222,12,'coasts',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (223,12,'coconut groves',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (224,12,'coliseums',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (225,12,'colleges',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (226,12,'collieries',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (227,12,'cols',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (228,12,'commemorative areas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (229,12,'commercial sites',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (230,12,'commissaries',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (231,12,'commons',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (232,12,'commonwealths',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (233,12,'communes',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (234,12,'communication centers',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (235,12,'communities',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (236,12,'community centers',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (237,12,'community houses',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (238,12,'companies',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (239,12,'compressor stations',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (240,12,'concert halls',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (241,12,'concession areas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (242,12,'condominiums',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (243,12,'cones (geological)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (244,12,'conference facilities',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (245,12,'confluences',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (246,12,'conservation areas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (247,12,'consulates',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (248,12,'continental divides',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (249,12,'continental margins',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (250,12,'continental rises',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (251,12,'continental shelves',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (252,12,'continental slopes',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (253,12,'continents',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (254,12,'control points',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (255,12,'convalescent centers',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (256,12,'convention centers',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (257,12,'convents',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (258,12,'cooper works',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (259,12,'copper mines',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (260,12,'coral reefs',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (261,12,'cordilleras',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (262,12,'corn belts',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (263,12,'corrals',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (264,12,'correctional facilities',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (265,12,'corridors',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (266,12,'cotton gins',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (267,12,'cotton plantations',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (268,12,'coulees',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (269,12,'counties',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (270,12,'countries',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (271,12,'countries, 1st order divisions',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (272,12,'countries, 2nd order divisions',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (273,12,'countries, 3rd order divisions',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (274,12,'countries, 4th order divisions',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (275,12,'country clubs',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (276,12,'country houses',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (277,12,'county seats',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (278,12,'court houses',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (279,12,'courthouses',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (280,12,'covered bridges',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (281,12,'covered reservoirs',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (282,12,'coves',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (283,12,'crags',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (284,12,'crater lakes',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (285,12,'craters',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (286,12,'creeks',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (287,12,'crevasses',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (288,12,'croplands',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (289,12,'crossings',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (290,12,'cuestas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (291,12,'cultivated areas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (292,12,'cultivated croplands',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (293,12,'currents',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (294,12,'customs houses',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (295,12,'customs posts',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (296,12,'cutoffs (hydrographic)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (297,12,'cwms',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (298,12,'dairies',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (299,12,'dam sites',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (300,12,'dams',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (301,12,'data collection facilities',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (302,12,'deep-sea trenches',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (303,12,'deeps (ocean)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (304,12,'defiles',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (305,12,'deltas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (306,12,'demilitarized zones',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (307,12,'demonstration areas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (308,12,'dependent political entities',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (309,12,'depots',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (310,12,'depressions',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (311,12,'deserts',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (312,12,'detention camps',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (313,12,'detention centers',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (314,12,'detention homes',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (315,12,'diatomite mines',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (316,12,'dikes (manmade)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (317,12,'dispensaries (medical)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (318,12,'disposal sites',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (319,12,'distilleries',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (320,12,'distributaries',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (321,12,'districts',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (322,12,'ditch mouths',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (323,12,'ditches',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (324,12,'dock yards',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (325,12,'docking basins',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (326,12,'docks',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (327,12,'dockyards',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (328,12,'domes (physiographic)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (329,12,'dormitories',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (330,12,'dragways',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (331,12,'drainage basins',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (332,12,'drainage canals',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (333,12,'drainage ditches',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (334,12,'drains (channels)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (335,12,'drawbridges',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (336,12,'drives',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (337,12,'drumlins',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (338,12,'dry docks',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (339,12,'dry lakes',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (340,12,'dry stream beds',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (341,12,'dumps',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (342,12,'dunes',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (343,12,'dwellings',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (344,12,'dykes (geologic)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (345,12,'earthquake features',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (346,12,'ecological research sites',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (347,12,'economic regions',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (348,12,'ecoregions',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (349,12,'eddies',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (350,12,'educational facilities',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (351,12,'electric plants',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (352,12,'elevators (agricultural)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (353,12,'embankments',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (354,12,'embassy buildings',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (355,12,'embayments',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (356,12,'environmental areas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (357,12,'equestrian centers',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (358,12,'escarpments',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (359,12,'eskers',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (360,12,'estates',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (361,12,'estuaries',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (362,12,'exhibition buildings',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (363,12,'experiment stations',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (364,12,'experimental areas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (365,12,'experimental fields',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (366,12,'facilities',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (367,12,'facility centers',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (368,12,'factories',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (369,12,'fairgrounds',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (370,12,'falls',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (371,12,'fans (alluvial)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (372,12,'farms',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (373,12,'farmsteads',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (374,12,'fault zones',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (375,12,'faults',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (376,12,'feedlots',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (377,12,'fens',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (378,12,'ferries',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (379,12,'field campaigns',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (380,12,'fields',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (381,12,'filter plants',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (382,12,'filtration plants',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (383,12,'fiords',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (384,12,'fire lookouts',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (385,12,'fire stations',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (386,12,'firebreaks',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (387,12,'firehouses',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (388,12,'first-order administrative divisions',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (389,12,'fish farms',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (390,12,'fish hatcheries',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (391,12,'fish ponds',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (392,12,'fisheries',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (393,12,'fishing areas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (394,12,'fishing lodges',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (395,12,'fishponds',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (396,12,'fissures',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (397,12,'fitness centers',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (398,12,'fjords',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (399,12,'flats',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (400,12,'flood control basins',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (401,12,'floodplains',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (402,12,'floodways',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (403,12,'flumes (manmade)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (404,12,'flumes (natural)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (405,12,'fluvial features',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (406,12,'folds (geologic)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (407,12,'football fields',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (408,12,'foothills',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (409,12,'fords (crossings)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (410,12,'forest reserves',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (411,12,'forest stations',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (412,12,'forested wetlands',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (413,12,'forests',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (414,12,'forges',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (415,12,'forks (physiographic features)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (416,12,'fortalices',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (417,12,'fortifications',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (418,12,'forts',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (419,12,'fossilized forests',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (420,12,'foundaries',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (421,12,'fourth-order administrative divisions',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (422,12,'fracture zones',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (423,12,'free trade zones',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (424,12,'freely associated states',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (425,12,'fringing reefs',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (426,12,'fuel depots',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (427,12,'fuelbreaks',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (428,12,'fumaroles',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (429,12,'furnaces (industrial)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (430,12,'furrows',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (431,12,'gaging stations',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (432,12,'galleries',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (433,12,'game management areas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (434,12,'gaps',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (435,12,'garages',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (436,12,'gardens',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (437,12,'gas fields',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (438,12,'gas pipelines',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (439,12,'gas-oil separation plants',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (440,12,'gasfields',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (441,12,'gates (manmade)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (442,12,'generating centers',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (443,12,'generation sites',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (444,12,'geodectic stations',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (445,12,'geographic centers',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (446,12,'geological features',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (447,12,'geysers',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (448,12,'glacier features',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (449,12,'glaciers',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (450,12,'glades',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (451,12,'glens',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (452,12,'gold mines',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (453,12,'golf clubs',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (454,12,'golf courses',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (455,12,'gorges',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (456,12,'governed places',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (457,12,'government, buildings',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (458,12,'grabens',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (459,12,'grades (physiographic)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (460,12,'granges',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (461,12,'grasslands',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (462,12,'grave sites',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (463,12,'gravel pits',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (464,12,'graves',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (465,12,'graveyards',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (466,12,'grazing allotments',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (467,12,'grazing areas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (468,12,'grist mills',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (469,12,'grottoes',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (470,12,'groves',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (471,12,'guard stations',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (472,12,'guest houses',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (473,12,'gulches',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (474,12,'gulfs',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (475,12,'gullies',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (476,12,'gun clubs',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (477,12,'guts',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (478,12,'guyots',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (479,12,'gymnasiums',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (480,12,'habitats',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (481,12,'halls',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (482,12,'halting places (transportation)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (483,12,'hamlets',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (484,12,'hammocks',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (485,12,'hanging valleys',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (486,12,'harbors',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (487,12,'harbours',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (488,12,'hatcheries',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (489,12,'headlands',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (490,12,'headquarters',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (491,12,'headstreams',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (492,12,'headwaters',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (493,12,'health facilities',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (494,12,'heaths',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (495,12,'helibases',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (496,12,'helipads',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (497,12,'heliports',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (498,12,'helistops',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (499,12,'hermitages',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (500,12,'highway maintenance sites',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (501,12,'highways',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (502,12,'hills',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (503,12,'historic sites',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (504,12,'historical landmarks',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (505,12,'historical markers',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (506,12,'historical parks',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (507,12,'historical sites',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (508,12,'hogbacks',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (509,12,'holes (seafloor)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (510,12,'hollows',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (511,12,'homes',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (512,12,'homesteads',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (513,12,'honor camps',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (514,12,'honor farms',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (515,12,'hospitals',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (516,12,'hostels',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (517,12,'hot springs',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (518,12,'hotels',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (519,12,'houses',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (520,12,'housing areas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (521,12,'housing developments',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (522,12,'hunt posts',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (523,12,'hunting lodges',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (524,12,'hunting reserves',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (525,12,'huts',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (526,12,'hydroelectric power stations',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (527,12,'hydrographic features',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (528,12,'hydrographic structures',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (529,12,'hydrothermal vents',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (530,12,'ice fields',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (531,12,'ice masses',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (532,12,'ice patches',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (533,12,'ice sheets',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (534,12,'ice skating rinks',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (535,12,'icebergs',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (536,12,'icecap depressions',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (537,12,'icecap domes',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (538,12,'icecap ridges',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (539,12,'icecaps',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (540,12,'icefalls',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (541,12,'incinerators',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (542,12,'inclines',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (543,12,'independent political entities',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (544,12,'indian reservations',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (545,12,'indian reserves',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (546,12,'industrial areas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (547,12,'industrial parks',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (548,12,'industrial sites',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (549,12,'infantry camps',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (550,12,'infirmaries',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (551,12,'inland seas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (552,12,'inlets',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (553,12,'inns',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (554,12,'inspection stations',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (555,12,'institutes',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (556,12,'institutional sites',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (557,12,'institutions',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (558,12,'interdune troughs',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (559,12,'interfluves',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (560,12,'intermittent lakes',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (561,12,'intermittent oxbow lakes',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (562,12,'intermittent ponds',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (563,12,'intermittent pools',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (564,12,'intermittent reservoirs',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (565,12,'intermittent salt lakes',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (566,12,'intermittent salt ponds',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (567,12,'intermittent streams',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (568,12,'intermittent wetlands',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (569,12,'intersections',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (570,12,'intertidal zones',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (571,12,'iron mines',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (572,12,'irrigated fields',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (573,12,'irrigation canals',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (574,12,'irrigation ditches',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (575,12,'irrigation systems',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (576,12,'island arcs',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (577,12,'islands',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (578,12,'isles',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (579,12,'islets',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (580,12,'isthmuses',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (581,12,'jails',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (582,12,'jetties',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (583,12,'judicial divisions',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (584,12,'jungles',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (585,12,'juvenile facilities',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (586,12,'karst areas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (587,12,'kavirs',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (588,12,'keys (islands)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (589,12,'knolls',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (590,12,'labor camps',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (591,12,'laboratories',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (592,12,'lagoons',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (593,12,'laguna',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (594,12,'lake beds',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (595,12,'lake channels',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (596,12,'lake districts',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (597,12,'lake regions',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (598,12,'lakes',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (599,12,'land grants',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (600,12,'land parcels',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (601,12,'land regions',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (602,12,'land-tied islands',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (603,12,'landfills',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (604,12,'landing fields',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (605,12,'landing strips',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (606,12,'landmarks (monuments)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (607,12,'landmarks (reference locations)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (608,12,'landslides',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (609,12,'laterals',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (610,12,'launch facilities',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (611,12,'lava areas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (612,12,'lava fields',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (613,12,'lead mines',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (614,12,'leased areas (government)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (615,12,'leased zones (government)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (616,12,'ledges',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (617,12,'legation buildings',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (618,12,'leper colonies',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (619,12,'leprosariums',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (620,12,'levees',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (621,12,'libraries',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (622,12,'library buildings',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (623,12,'light houses',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (624,12,'light stations',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (625,12,'lighthouses',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (626,12,'limekilns',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (627,12,'linguistic regions',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (628,12,'llanos',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (629,12,'locales',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (630,12,'localities',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (631,12,'lochs',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (632,12,'locks',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (633,12,'lodes (mineral)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (634,12,'lodges',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (635,12,'logging camps',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (636,12,'lookout (vista)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (637,12,'lost rivers',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (638,12,'lots (land parcels)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (639,12,'LTERs',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (640,12,'malls',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (641,12,'management areas (reserves)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (642,12,'maneuver areas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (643,12,'mangrove islands',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (644,12,'mangrove swamps',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (645,12,'manmade features',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (646,12,'mansions',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (647,12,'map quadrangle regions',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (648,12,'map regions',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (649,12,'marinas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (650,12,'marine channels',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (651,12,'marine features',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (652,12,'marine parks',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (653,12,'marine regions',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (654,12,'marine terminals',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (655,12,'markers',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (656,12,'marketplaces',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (657,12,'markets',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (658,12,'marshes',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (659,12,'massacre sites',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (660,12,'massifs',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (661,12,'mausoleums',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (662,12,'meadows',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (663,12,'meander necks',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (664,12,'meanders',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (665,12,'median valleys',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (666,12,'medical centers',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (667,12,'medical facilities',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (668,12,'memorial gardens',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (669,12,'memorials',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (670,12,'mesas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (671,12,'meteorological stations',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (672,12,'metropolitan areas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (673,12,'Metropolitan Statistical Areas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (674,12,'metrorail stations',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (675,12,'milestones',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (676,12,'military areas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (677,12,'military bases',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (678,12,'military installations',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (679,12,'military schools',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (680,12,'mill sites',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (681,12,'millponds',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (682,12,'mills',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (683,12,'millsites',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (684,12,'mine dumps',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (685,12,'mine entrances',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (686,12,'mine shafts',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (687,12,'mine sites',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (688,12,'mineral deposit areas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (689,12,'mineral springs',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (690,12,'mines',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (691,12,'mining areas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (692,12,'mining camps',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (693,12,'mires',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (694,12,'missile sites',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (695,12,'missions',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (696,12,'moats (manmade)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (697,12,'moats (seafloor)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (698,12,'mobile home parks',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (699,12,'mobile home sites',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (700,12,'moles (structural)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (701,12,'monasteries',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (702,12,'monuments',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (703,12,'moorings',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (704,12,'moors',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (705,12,'moraines',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (706,12,'mosques',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (707,12,'motels',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (708,12,'mounds',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (709,12,'mountain crests',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (710,12,'mountain ranges',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (711,12,'mountain summits',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (712,12,'mountains',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (713,12,'mounts',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (714,12,'MSAs',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (715,12,'mud flats',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (716,12,'multinational entities',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (717,12,'municipal courts',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (718,12,'municipalities',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (719,12,'municipios',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (720,12,'munitions plants',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (721,12,'museum buildings',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (722,12,'museums',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (723,12,'narrows (hydrographic)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (724,12,'natatoriums',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (725,12,'national capitals',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (726,12,'national forests',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (727,12,'national guard facilities',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (728,12,'national monuments',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (729,12,'national parks',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (730,12,'national seashores',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (731,12,'nations',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (732,12,'natural areas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (733,12,'natural bridges',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (734,12,'natural rock formations',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (735,12,'natural tunnels',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (736,12,'nature reserves',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (737,12,'naval bases',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (738,12,'navigation canals',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (739,12,'navigation channels',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (740,12,'neighborhood centers',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (741,12,'neighborhoods (residential)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (742,12,'neutral zones (political)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (743,12,'nickel mines',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (744,12,'novitiates',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (745,12,'nuclear power plants',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (746,12,'nunataks',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (747,12,'nurseries',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (748,12,'nursing homes',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (749,12,'oases',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (750,12,'oblasts',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (751,12,'observation points',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (752,12,'observation sites',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (753,12,'observatories',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (754,12,'observatorios',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (755,12,'ocean currents',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (756,12,'ocean floor features',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (757,12,'ocean regions',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (758,12,'ocean trenches',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (759,12,'oceans',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (760,12,'offices',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (761,12,'offshore areas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (762,12,'offshore platforms',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (763,12,'oil camps',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (764,12,'oil fields',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (765,12,'oil palm plantations',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (766,12,'oil pipeline junctions',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (767,12,'oil pipeline terminals',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (768,12,'oil pipelines',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (769,12,'oil platforms',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (770,12,'oil pumping stations',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (771,12,'oil refineries',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (772,12,'oil wells',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (773,12,'oilfields',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (774,12,'olive groves',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (775,12,'olive oil mills',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (776,12,'open pit mines',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (777,12,'opera houses',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (778,12,'orchards',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (779,12,'ore treatment plants',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (780,12,'orphanages',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (781,12,'overfalls',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (782,12,'overpasses',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (783,12,'oxbow lakes',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (784,12,'pagodas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (785,12,'palaces',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (786,12,'paleontological sites',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (787,12,'palm groves',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (788,12,'palm tree reserves',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (789,12,'pampas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (790,12,'pans (geologic)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (791,12,'parishes',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (792,12,'park gates',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (793,12,'park headquarters',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (794,12,'parking lots',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (795,12,'parking sites',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (796,12,'parks',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (797,12,'parkways',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (798,12,'parsonages',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (799,12,'passes',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (800,12,'pastoral sites',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (801,12,'pastures',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (802,12,'patrol posts',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (803,12,'pavilions',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (804,12,'peaks',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (805,12,'peat cutting areas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (806,12,'peatlands',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (807,12,'penal camps',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (808,12,'penal farms',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (809,12,'peninsulas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (810,12,'penitentiaries',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (811,12,'performance sites',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (812,12,'petrified forests',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (813,12,'petroglyphs',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (814,12,'petroleum basins',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (815,12,'petroleum fields',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (816,12,'phosphate works',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (817,12,'physical education facilities',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (818,12,'physiographic features',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (819,12,'picnic areas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (820,12,'piers',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (821,12,'pillars (natural formation)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (822,12,'pine groves',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (823,12,'pinnacles (natural formation)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (824,12,'pipelines',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (825,12,'pistol ranges (sport)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (826,12,'pitches (physiographic)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (827,12,'placer mines',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (828,12,'placers',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (829,12,'plains',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (830,12,'planetariums',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (831,12,'plantations',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (832,12,'plants (industrial)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (833,12,'plaques',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (834,12,'plateaus',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (835,12,'platforms (continental margins)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (836,12,'platforms (offshore)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (837,12,'playas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (838,12,'playgrounds',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (839,12,'playhouses',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (840,12,'plazas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (841,12,'points (physiographic)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (842,12,'polders',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (843,12,'poles (sphere)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (844,12,'police posts',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (845,12,'political areas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (846,12,'political entities',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (847,12,'polo fields',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (848,12,'ponds',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (849,12,'pools (water bodies)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (850,12,'pools, swimming',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (851,12,'populated localities',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (852,12,'populated places',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (853,12,'portages',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (854,12,'ports',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (855,12,'post office buildings',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (856,12,'post offices',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (857,12,'postal areas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (858,12,'potholes',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (859,12,'power generation sites',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (860,12,'power plants',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (861,12,'power stations',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (862,12,'powerhouses',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (863,12,'ppl',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (864,12,'prairies',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (865,12,'precincts',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (866,12,'precipices',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (867,12,'prefectures',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (868,12,'preserves',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (869,12,'primitive areas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (870,12,'prisons',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (871,12,'processing plants',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (872,12,'production buildings',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (873,12,'promenades',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (874,12,'promontories',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (875,12,'protected areas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (876,12,'protectorates',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (877,12,'provinces',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (878,12,'provincial parks',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (879,12,'proving grounds',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (880,12,'public buildings',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (881,12,'public use areas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (882,12,'pueblos',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (883,12,'pump houses',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (884,12,'pumphouses',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (885,12,'pumping stations',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (886,12,'pyramids',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (887,12,'quadrangle regions',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (888,12,'quagmires',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (889,12,'quarries',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (890,12,'quays',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (891,12,'quebradas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (892,12,'quicksand areas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (893,12,'race tracks',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (894,12,'racecourses',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (895,12,'racetracks',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (896,12,'raceways',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (897,12,'radio observatories',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (898,12,'radio stations',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (899,12,'railroad features',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (900,12,'railroad junctions',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (901,12,'railroad sidings',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (902,12,'railroad spurs',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (903,12,'railroad stations',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (904,12,'railroad stops',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (905,12,'railroad switches',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (906,12,'railroad tunnels',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (907,12,'railroad yards',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (908,12,'railways',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (909,12,'rain forests',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (910,12,'ramps (seafloor)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (911,12,'ranches',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (912,12,'ranger stations',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (913,12,'ranges (physiographic)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (914,12,'rapids',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (915,12,'ravines',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (916,12,'reaches (hydrographic)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (917,12,'recital halls',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (918,12,'recreation areas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (919,12,'recreation sites',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (920,12,'recreational facilities',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (921,12,'rectories',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (922,12,'redoubts',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (923,12,'reefs',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (924,12,'reference locations',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (925,12,'refineries',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (926,12,'reflectors',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (927,12,'reformatories',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (928,12,'refugee camps',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (929,12,'refuse disposal sites',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (930,12,'regions',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (931,12,'rehabilitation centers',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (932,12,'religious centers',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (933,12,'religious facilities',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (934,12,'religious populated places',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (935,12,'religious sites',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (936,12,'republics',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (937,12,'research areas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (938,12,'research facilities',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (939,12,'research institutes',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (940,12,'reservations (indian)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (941,12,'reservations (nature sites)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (942,12,'reserves',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (943,12,'reservoirs',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (944,12,'residences',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (945,12,'residential sites',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (946,12,'resorts',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (947,12,'rest areas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (948,12,'restaurants',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (949,12,'resthouses',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (950,12,'retention basins',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (951,12,'retreats (religious)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (952,12,'revetments',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (953,12,'rice fields',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (954,12,'rice growing regions',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (955,12,'ridges',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (956,12,'riding stables',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (957,12,'rifle ranges',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (958,12,'rift zones',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (959,12,'rios',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (960,12,'riparian areas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (961,12,'rises (seafloor)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (962,12,'river bends',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (963,12,'rivers',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (964,12,'road bends',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (965,12,'road cuts',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (966,12,'road junctions',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (967,12,'road tunnels',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (968,12,'roadless areas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (969,12,'roads',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (970,12,'roadsteads (anchorages)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (971,12,'roadways',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (972,12,'rock deserts',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (973,12,'rock towers',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (974,12,'rockfalls',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (975,12,'rocks',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (976,12,'rodeo grounds',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (977,12,'rookeries',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (978,12,'routes',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (979,12,'rowhouses',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (980,12,'rubber plantations',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (981,12,'ruins',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (982,12,'runways',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (983,12,'RV parks',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (984,12,'sabkhas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (985,12,'saddles (physiographic)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (986,12,'salt deposit areas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (987,12,'salt evaporation ponds',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (988,12,'salt lakes',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (989,12,'salt marshes',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (990,12,'salt mines',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (991,12,'salt ponds',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (992,12,'sanatariums',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (993,12,'sanatoriums',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (994,12,'sanctuaries (religious)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (995,12,'sanctuaries (wildlife)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (996,12,'sandbars',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (997,12,'sandy areas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (998,12,'sandy deserts',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (999,12,'sanitary landfills',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1000,12,'satellite stations',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1001,12,'savannahs',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1002,12,'savannas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1003,12,'sawmills',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1004,12,'scenic areas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1005,12,'school districts',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1006,12,'schools',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1007,12,'scientific research bases',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1008,12,'scrap yards',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1009,12,'scraps',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1010,12,'scrublands',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1011,12,'sea arches',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1012,12,'seachannels (seafloor)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1013,12,'seafloor features',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1014,12,'seamounts',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1015,12,'seapeaks',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1016,12,'seaplane bases',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1017,12,'seaplane landing areas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1018,12,'seaports',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1019,12,'seas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1020,12,'seawalls',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1021,12,'second-order administrative divisions',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1022,12,'semi-independent political entities',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1023,12,'seminaries',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1024,12,'sepulchers',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1025,12,'settlements',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1026,12,'sewage treatment plants',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1027,12,'sheepfolds',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1028,12,'sheikdoms',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1029,12,'shelf edges (ocean)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1030,12,'shelf valleys (seafloor)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1031,12,'shelters',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1032,12,'shelves, continental',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1033,12,'ship tracks',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1034,12,'shoals',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1035,12,'shooting ranges (sport)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1036,12,'shopping centers',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1037,12,'shopping malls',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1038,12,'shops',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1039,12,'shorelines',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1040,12,'shores',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1041,12,'shrines',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1042,12,'shrublands',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1043,12,'sierra',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1044,12,'sills (physiographic)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1045,12,'sinkholes',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1046,12,'sinks',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1047,12,'siphon (physiographic)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1048,12,'sisal plantations',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1049,12,'skeet shooting ranges',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1050,12,'ski areas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1051,12,'ski facilities',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1052,12,'ski trails',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1053,12,'slag heaps',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1054,12,'slides (natural)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1055,12,'slopes',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1056,12,'sloughs',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1057,12,'slues',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1058,12,'sluices',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1059,12,'smelters',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1060,12,'snow regions',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1061,12,'snowfields',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1062,12,'solar power generation sites',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1063,12,'sounds (bodies of water)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1064,12,'space centers',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1065,12,'spas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1066,12,'speedways',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1067,12,'spillways',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1068,12,'spits',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1069,12,'sports facilities',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1070,12,'sportsman lodges',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1071,12,'springs (hydrographic)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1072,12,'spurs (physiographic)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1073,12,'stables',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1074,12,'stadiums',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1075,12,'stages (performance)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1076,12,'state capitals',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1077,12,'state forests',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1078,12,'state parks',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1079,12,'states',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1080,12,'stations',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1081,12,'statistical areas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1082,12,'statues',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1083,12,'steam plants',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1084,12,'steps (manmade)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1085,12,'stock routes',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1086,12,'stockades',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1087,12,'stockyards',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1088,12,'stones',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1089,12,'stony deserts',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1090,12,'storage basins',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1091,12,'storage fields (petroleum)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1092,12,'storage structures',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1093,12,'storage tanks',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1094,12,'storehouses',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1095,12,'stores',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1096,12,'straits',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1097,12,'strands',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1098,12,'stream banks',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1099,12,'stream bends',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1100,12,'stream mouths',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1101,12,'streams',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1102,12,'streets',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1103,12,'strip mines',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1104,12,'structures',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1105,12,'student unions',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1106,12,'studios',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1107,12,'study areas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1108,12,'sub-surface dams',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1109,12,'subcontinents',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1110,12,'subdivisions',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1111,12,'submarine canyons',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1112,12,'subsea features',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1113,12,'substations',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1114,12,'suburbs',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1115,12,'subway stations',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1116,12,'sugar mills',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1117,12,'sugar plantations',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1118,12,'sugar refineries',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1119,12,'sulfur springs',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1120,12,'sultanates',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1121,12,'summits',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1122,12,'swamps',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1123,12,'swim clubs',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1124,12,'swimming pools',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1125,12,'switches (railroad)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1126,12,'symphony halls',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1127,12,'synagogues',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1128,12,'synclines',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1129,12,'tabernacles',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1130,12,'table mountains',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1131,12,'tablelands',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1132,12,'tablemounts (seafloor)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1133,12,'tailing ponds',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1134,12,'tailings',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1135,12,'talus slopes',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1136,12,'tank farms',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1137,12,'tarns',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1138,12,'taverns',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1139,12,'tea plantations',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1140,12,'tectonic features',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1141,12,'telecommunication features',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1142,12,'telescopes',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1143,12,'television stations',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1144,12,'temples',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1145,12,'tennis clubs',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1146,12,'tennis courts',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1147,12,'terminals (transportation)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1148,12,'terraces (physiographic)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1149,12,'territorial waters',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1150,12,'territories',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1151,12,'test sites',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1152,12,'theaters',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1153,12,'theatres',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1154,12,'thermal features',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1155,12,'third-order administrative divisions',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1156,12,'tidal creeks',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1157,12,'tidal flats',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1158,12,'tin mines',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1159,12,'tombs',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1160,12,'tongues (seafloor)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1161,12,'topographic quadrangle regions',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1162,12,'towers',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1163,12,'town halls',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1164,12,'towns',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1165,12,'township and range areas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1166,12,'townships',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1167,12,'tracts',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1168,12,'trade zones',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1169,12,'trading posts',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1170,12,'traffic circles',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1171,12,'trailer parks (recreational)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1172,12,'trailer parks (residential)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1173,12,'trailheads',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1174,12,'trails',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1175,12,'training centers',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1176,12,'tramways',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1177,12,'transit facilities',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1178,12,'transmission lines',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1179,12,'transportation features',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1180,12,'treatment plants',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1181,12,'trees',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1182,12,'trenches (seafloor)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1183,12,'trestles',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1184,12,'triangulation stations',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1185,12,'tribal areas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1186,12,'tributaries',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1187,12,'troughs (seafloor)',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1188,12,'trout farms',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1189,12,'tundras',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1190,12,'tunnels',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1191,12,'turning basins',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1192,12,'underground irrigation canals',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1193,12,'underground lakes',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1194,12,'underwater features',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1195,12,'United States Government establishments',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1196,12,'universities',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1197,12,'uplands',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1198,12,'upwellings',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1199,12,'urban areas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1200,12,'urban parks',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1201,12,'UTM zones',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1202,12,'valleys',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1203,12,'vegetation',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1204,12,'veterinary facilities',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1205,12,'viaducts',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1206,12,'viewing locations',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1207,12,'village squares',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1208,12,'villages',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1209,12,'villas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1210,12,'vineyards',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1211,12,'visitor centers',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1212,12,'vistas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1213,12,'volcanic features',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1214,12,'volcanoes',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1215,12,'wadi bends',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1216,12,'wadi junctions',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1217,12,'wadi mouths',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1218,12,'wadis',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1219,12,'walking paths',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1220,12,'walls',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1221,12,'war zones',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1222,12,'warehouses',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1223,12,'washes',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1224,12,'waste disposal sites',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1225,12,'water bodies',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1226,12,'water mills',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1227,12,'water plants',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1228,12,'water pumping stations',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1229,12,'water tanks',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1230,12,'water treatment plants',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1231,12,'water wells',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1232,12,'water works',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1233,12,'watercourses',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1234,12,'waterfalls',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1235,12,'waterholes',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1236,12,'watersheds',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1237,12,'waterworks',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1238,12,'weather stations',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1239,12,'weirs',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1240,12,'wells',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1241,12,'wetlands',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1242,12,'whaling stations',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1243,12,'wharves',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1244,12,'wheat belts',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1245,12,'whirlpools',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1246,12,'wilderness areas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1247,12,'wildlife areas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1248,12,'wildlife refuges',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1249,12,'wildlife reserves',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1250,12,'windmill power generation sites',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1251,12,'windmills',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1252,12,'wineries',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1253,12,'woods',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1254,12,'wreck sites',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1255,12,'wrecking yards',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1256,12,'wrecks',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1257,12,'yacht clubs',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1258,12,'youth centers',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1259,12,'youth facilities',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1260,12,'zip code areas',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1261,12,'zoological gardens',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1262,12,'zoos',NULL,NULL,NULL);

INSERT INTO l_scheme_term_parent SELECT 1, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='abyssal features' AND T2.term='seafloor features';
INSERT INTO l_scheme_term_parent SELECT 2, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='agricultural regions' AND T2.term='regions';
INSERT INTO l_scheme_term_parent SELECT 3, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='agricultural sites' AND T2.term='manmade features';
INSERT INTO l_scheme_term_parent SELECT 4, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='airport features' AND T2.term='transportation features';
INSERT INTO l_scheme_term_parent SELECT 5, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='alluvial fans' AND T2.term='physiographic features';
INSERT INTO l_scheme_term_parent SELECT 6, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='amusement parks' AND T2.term='recreational facilities';
INSERT INTO l_scheme_term_parent SELECT 7, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='anticlines' AND T2.term='folds (geologic)';
INSERT INTO l_scheme_term_parent SELECT 8, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='aqueducts' AND T2.term='transportation features';
INSERT INTO l_scheme_term_parent SELECT 9, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='aquifers' AND T2.term='hydrographic features';
INSERT INTO l_scheme_term_parent SELECT 10, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='archaeological sites' AND T2.term='historical sites';
INSERT INTO l_scheme_term_parent SELECT 11, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='arches (natural formation)' AND T2.term='natural rock formations';
INSERT INTO l_scheme_term_parent SELECT 12, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='archipelagos' AND T2.term='islands';
INSERT INTO l_scheme_term_parent SELECT 13, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='arroyos' AND T2.term='physiographic features';
INSERT INTO l_scheme_term_parent SELECT 14, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='badlands' AND T2.term='physiographic features';
INSERT INTO l_scheme_term_parent SELECT 15, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='banks (hydrographic)' AND T2.term='physiographic features';
INSERT INTO l_scheme_term_parent SELECT 16, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='barren lands' AND T2.term='biogeographic regions';
INSERT INTO l_scheme_term_parent SELECT 17, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='bars (physiographic)' AND T2.term='physiographic features';
INSERT INTO l_scheme_term_parent SELECT 18, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='basins' AND T2.term='physiographic features';
INSERT INTO l_scheme_term_parent SELECT 19, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='bays' AND T2.term='hydrographic features';
INSERT INTO l_scheme_term_parent SELECT 20, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='beaches' AND T2.term='physiographic features';
INSERT INTO l_scheme_term_parent SELECT 21, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='bends (river)' AND T2.term='rivers';
INSERT INTO l_scheme_term_parent SELECT 22, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='bights' AND T2.term='physiographic features';
INSERT INTO l_scheme_term_parent SELECT 23, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='biogeographic regions' AND T2.term='regions';
INSERT INTO l_scheme_term_parent SELECT 24, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='breakwaters' AND T2.term='hydrographic structures';
INSERT INTO l_scheme_term_parent SELECT 25, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='bridges' AND T2.term='transportation features';
INSERT INTO l_scheme_term_parent SELECT 26, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='buildings' AND T2.term='manmade features';
INSERT INTO l_scheme_term_parent SELECT 27, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='cableways' AND T2.term='transportation features';
INSERT INTO l_scheme_term_parent SELECT 28, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='cadastral areas' AND T2.term='administrative areas';
INSERT INTO l_scheme_term_parent SELECT 29, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='camps' AND T2.term='recreational facilities';
INSERT INTO l_scheme_term_parent SELECT 30, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='canals' AND T2.term='hydrographic structures';
INSERT INTO l_scheme_term_parent SELECT 31, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='canyons' AND T2.term='valleys';
INSERT INTO l_scheme_term_parent SELECT 32, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='capes' AND T2.term='physiographic features';
INSERT INTO l_scheme_term_parent SELECT 33, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='capitals' AND T2.term='cities';
INSERT INTO l_scheme_term_parent SELECT 34, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='capitol buildings' AND T2.term='buildings';
INSERT INTO l_scheme_term_parent SELECT 35, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='caves' AND T2.term='physiographic features';
INSERT INTO l_scheme_term_parent SELECT 36, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='cemeteries' AND T2.term='manmade features';
INSERT INTO l_scheme_term_parent SELECT 37, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='census areas' AND T2.term='statistical areas';
INSERT INTO l_scheme_term_parent SELECT 38, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='channels' AND T2.term='hydrographic features';
INSERT INTO l_scheme_term_parent SELECT 39, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='chart regions' AND T2.term='map regions';
INSERT INTO l_scheme_term_parent SELECT 40, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='cirques' AND T2.term='physiographic features';
INSERT INTO l_scheme_term_parent SELECT 41, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='cities' AND T2.term='populated places';
INSERT INTO l_scheme_term_parent SELECT 42, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='cliffs' AND T2.term='physiographic features';
INSERT INTO l_scheme_term_parent SELECT 43, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='climatic regions' AND T2.term='regions';
INSERT INTO l_scheme_term_parent SELECT 44, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='coastal zones' AND T2.term='regions';
INSERT INTO l_scheme_term_parent SELECT 45, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='commercial sites' AND T2.term='buildings';
INSERT INTO l_scheme_term_parent SELECT 46, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='continental divides' AND T2.term='mountains';
INSERT INTO l_scheme_term_parent SELECT 47, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='continental margins' AND T2.term='seafloor features';
INSERT INTO l_scheme_term_parent SELECT 48, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='continents' AND T2.term='land regions';
INSERT INTO l_scheme_term_parent SELECT 49, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='coral reefs' AND T2.term='reefs';
INSERT INTO l_scheme_term_parent SELECT 50, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='correctional facilities' AND T2.term='institutional sites';
INSERT INTO l_scheme_term_parent SELECT 51, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='countries' AND T2.term='political areas';
INSERT INTO l_scheme_term_parent SELECT 52, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='countries, 1st order divisions' AND T2.term='political areas';
INSERT INTO l_scheme_term_parent SELECT 53, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='countries, 2nd order divisions' AND T2.term='political areas';
INSERT INTO l_scheme_term_parent SELECT 54, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='countries, 3rd order divisions' AND T2.term='political areas';
INSERT INTO l_scheme_term_parent SELECT 55, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='countries, 4th order divisions' AND T2.term='political areas';
INSERT INTO l_scheme_term_parent SELECT 56, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='court houses' AND T2.term='buildings';
INSERT INTO l_scheme_term_parent SELECT 57, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='craters' AND T2.term='physiographic features';
INSERT INTO l_scheme_term_parent SELECT 58, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='dam sites' AND T2.term='hydrographic structures';
INSERT INTO l_scheme_term_parent SELECT 59, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='data collection facilities' AND T2.term='research facilities';
INSERT INTO l_scheme_term_parent SELECT 60, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='deltas' AND T2.term='physiographic features';
INSERT INTO l_scheme_term_parent SELECT 61, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='deserts' AND T2.term='biogeographic regions';
INSERT INTO l_scheme_term_parent SELECT 62, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='disposal sites' AND T2.term='manmade features';
INSERT INTO l_scheme_term_parent SELECT 63, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='drainage basins' AND T2.term='hydrographic features';
INSERT INTO l_scheme_term_parent SELECT 64, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='drumlins' AND T2.term='ridges';
INSERT INTO l_scheme_term_parent SELECT 65, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='dunes' AND T2.term='physiographic features';
INSERT INTO l_scheme_term_parent SELECT 66, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='earthquake features' AND T2.term='tectonic features';
INSERT INTO l_scheme_term_parent SELECT 67, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='ecological research sites' AND T2.term='research areas';
INSERT INTO l_scheme_term_parent SELECT 68, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='economic regions' AND T2.term='regions';
INSERT INTO l_scheme_term_parent SELECT 69, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='educational facilities' AND T2.term='institutional sites';
INSERT INTO l_scheme_term_parent SELECT 70, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='estuaries' AND T2.term='hydrographic features';
INSERT INTO l_scheme_term_parent SELECT 71, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='fault zones' AND T2.term='faults';
INSERT INTO l_scheme_term_parent SELECT 72, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='faults' AND T2.term='tectonic features';
INSERT INTO l_scheme_term_parent SELECT 73, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='firebreaks' AND T2.term='manmade features';
INSERT INTO l_scheme_term_parent SELECT 74, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='fisheries' AND T2.term='manmade features';
INSERT INTO l_scheme_term_parent SELECT 75, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='fjords' AND T2.term='bays';
INSERT INTO l_scheme_term_parent SELECT 76, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='flats' AND T2.term='physiographic features';
INSERT INTO l_scheme_term_parent SELECT 77, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='floodplains' AND T2.term='hydrographic features';
INSERT INTO l_scheme_term_parent SELECT 78, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='folds (geologic)' AND T2.term='tectonic features';
INSERT INTO l_scheme_term_parent SELECT 79, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='forests' AND T2.term='biogeographic regions';
INSERT INTO l_scheme_term_parent SELECT 80, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='fortifications' AND T2.term='manmade features';
INSERT INTO l_scheme_term_parent SELECT 81, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='fracture zones' AND T2.term='seafloor features';
INSERT INTO l_scheme_term_parent SELECT 82, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='gaging stations' AND T2.term='hydrographic structures';
INSERT INTO l_scheme_term_parent SELECT 83, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='gaps' AND T2.term='physiographic features';
INSERT INTO l_scheme_term_parent SELECT 84, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='glacier features' AND T2.term='ice masses';
INSERT INTO l_scheme_term_parent SELECT 85, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='grasslands' AND T2.term='biogeographic regions';
INSERT INTO l_scheme_term_parent SELECT 86, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='gulfs' AND T2.term='hydrographic features';
INSERT INTO l_scheme_term_parent SELECT 87, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='guts' AND T2.term='hydrographic features';
INSERT INTO l_scheme_term_parent SELECT 88, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='habitats' AND T2.term='biogeographic regions';
INSERT INTO l_scheme_term_parent SELECT 89, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='harbors' AND T2.term='hydrographic structures';
INSERT INTO l_scheme_term_parent SELECT 90, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='heliports' AND T2.term='airport features';
INSERT INTO l_scheme_term_parent SELECT 91, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='historical sites' AND T2.term='manmade features';
INSERT INTO l_scheme_term_parent SELECT 92, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='housing areas' AND T2.term='residential sites';
INSERT INTO l_scheme_term_parent SELECT 93, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='hydrographic structures' AND T2.term='manmade features';
INSERT INTO l_scheme_term_parent SELECT 94, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='hydrothermal vents' AND T2.term='seafloor features';
INSERT INTO l_scheme_term_parent SELECT 95, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='ice masses' AND T2.term='hydrographic features';
INSERT INTO l_scheme_term_parent SELECT 96, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='industrial sites' AND T2.term='commercial sites';
INSERT INTO l_scheme_term_parent SELECT 97, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='institutional sites' AND T2.term='buildings';
INSERT INTO l_scheme_term_parent SELECT 98, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='islands' AND T2.term='land regions';
INSERT INTO l_scheme_term_parent SELECT 99, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='isthmuses' AND T2.term='physiographic features';
INSERT INTO l_scheme_term_parent SELECT 100, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='jungles' AND T2.term='biogeographic regions';
INSERT INTO l_scheme_term_parent SELECT 101, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='karst areas' AND T2.term='physiographic features';
INSERT INTO l_scheme_term_parent SELECT 102, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='lakes' AND T2.term='hydrographic features';
INSERT INTO l_scheme_term_parent SELECT 103, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='land regions' AND T2.term='regions';
INSERT INTO l_scheme_term_parent SELECT 104, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='launch facilities' AND T2.term='manmade features';
INSERT INTO l_scheme_term_parent SELECT 105, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='lava fields' AND T2.term='volcanic features';
INSERT INTO l_scheme_term_parent SELECT 106, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='ledges' AND T2.term='physiographic features';
INSERT INTO l_scheme_term_parent SELECT 107, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='levees' AND T2.term='hydrographic structures';
INSERT INTO l_scheme_term_parent SELECT 108, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='library buildings' AND T2.term='buildings';
INSERT INTO l_scheme_term_parent SELECT 109, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='linguistic regions' AND T2.term='regions';
INSERT INTO l_scheme_term_parent SELECT 110, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='locks' AND T2.term='transportation features';
INSERT INTO l_scheme_term_parent SELECT 111, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='map quadrangle regions' AND T2.term='map regions';
INSERT INTO l_scheme_term_parent SELECT 112, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='map regions' AND T2.term='regions';
INSERT INTO l_scheme_term_parent SELECT 113, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='marinas' AND T2.term='harbors';
INSERT INTO l_scheme_term_parent SELECT 114, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='massifs' AND T2.term='physiographic features';
INSERT INTO l_scheme_term_parent SELECT 115, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='medical facilities' AND T2.term='institutional sites';
INSERT INTO l_scheme_term_parent SELECT 116, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='mesas' AND T2.term='physiographic features';
INSERT INTO l_scheme_term_parent SELECT 117, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='Metropolitan Statistical Areas' AND T2.term='statistical areas';
INSERT INTO l_scheme_term_parent SELECT 118, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='military areas' AND T2.term='administrative areas';
INSERT INTO l_scheme_term_parent SELECT 119, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='mine sites' AND T2.term='manmade features';
INSERT INTO l_scheme_term_parent SELECT 120, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='mineral deposit areas' AND T2.term='physiographic features';
INSERT INTO l_scheme_term_parent SELECT 121, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='mobile home parks' AND T2.term='residential sites';
INSERT INTO l_scheme_term_parent SELECT 122, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='monuments' AND T2.term='manmade features';
INSERT INTO l_scheme_term_parent SELECT 123, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='moraines' AND T2.term='physiographic features';
INSERT INTO l_scheme_term_parent SELECT 124, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='mountain ranges' AND T2.term='mountains';
INSERT INTO l_scheme_term_parent SELECT 125, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='mountain summits' AND T2.term='mountains';
INSERT INTO l_scheme_term_parent SELECT 126, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='mountains' AND T2.term='physiographic features';
INSERT INTO l_scheme_term_parent SELECT 127, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='multinational entities' AND T2.term='political areas';
INSERT INTO l_scheme_term_parent SELECT 128, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='museum buildings' AND T2.term='buildings';
INSERT INTO l_scheme_term_parent SELECT 129, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='natural rock formations' AND T2.term='physiographic features';
INSERT INTO l_scheme_term_parent SELECT 130, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='oases' AND T2.term='biogeographic regions';
INSERT INTO l_scheme_term_parent SELECT 131, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='ocean currents' AND T2.term='oceans';
INSERT INTO l_scheme_term_parent SELECT 132, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='ocean regions' AND T2.term='oceans';
INSERT INTO l_scheme_term_parent SELECT 133, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='ocean trenches' AND T2.term='seafloor features';
INSERT INTO l_scheme_term_parent SELECT 134, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='oceans' AND T2.term='seas';
INSERT INTO l_scheme_term_parent SELECT 135, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='offshore platforms' AND T2.term='hydrographic structures';
INSERT INTO l_scheme_term_parent SELECT 136, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='oil fields' AND T2.term='manmade features';
INSERT INTO l_scheme_term_parent SELECT 137, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='paleontological sites' AND T2.term='research areas';
INSERT INTO l_scheme_term_parent SELECT 138, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='parking sites' AND T2.term='transportation features';
INSERT INTO l_scheme_term_parent SELECT 139, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='parks' AND T2.term='manmade features';
INSERT INTO l_scheme_term_parent SELECT 140, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='performance sites' AND T2.term='recreational facilities';
INSERT INTO l_scheme_term_parent SELECT 141, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='petrified forests' AND T2.term='forests';
INSERT INTO l_scheme_term_parent SELECT 142, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='piers' AND T2.term='hydrographic structures';
INSERT INTO l_scheme_term_parent SELECT 143, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='pipelines' AND T2.term='transportation features';
INSERT INTO l_scheme_term_parent SELECT 144, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='plains' AND T2.term='physiographic features';
INSERT INTO l_scheme_term_parent SELECT 145, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='plateaus' AND T2.term='physiographic features';
INSERT INTO l_scheme_term_parent SELECT 146, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='playas' AND T2.term='physiographic features';
INSERT INTO l_scheme_term_parent SELECT 147, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='political areas' AND T2.term='administrative areas';
INSERT INTO l_scheme_term_parent SELECT 148, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='populated places' AND T2.term='administrative areas';
INSERT INTO l_scheme_term_parent SELECT 149, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='post office buildings' AND T2.term='buildings';
INSERT INTO l_scheme_term_parent SELECT 150, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='postal areas' AND T2.term='administrative areas';
INSERT INTO l_scheme_term_parent SELECT 151, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='power generation sites' AND T2.term='industrial sites';
INSERT INTO l_scheme_term_parent SELECT 152, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='railroad features' AND T2.term='transportation features';
INSERT INTO l_scheme_term_parent SELECT 153, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='rain forests' AND T2.term='forests';
INSERT INTO l_scheme_term_parent SELECT 154, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='rapids' AND T2.term='rivers';
INSERT INTO l_scheme_term_parent SELECT 155, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='recreational facilities' AND T2.term='manmade features';
INSERT INTO l_scheme_term_parent SELECT 156, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='reefs' AND T2.term='physiographic features';
INSERT INTO l_scheme_term_parent SELECT 157, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='reference locations' AND T2.term='manmade features';
INSERT INTO l_scheme_term_parent SELECT 158, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='religious facilities' AND T2.term='institutional sites';
INSERT INTO l_scheme_term_parent SELECT 159, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='research areas' AND T2.term='manmade features';
INSERT INTO l_scheme_term_parent SELECT 160, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='research facilities' AND T2.term='buildings';
INSERT INTO l_scheme_term_parent SELECT 161, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='reserves' AND T2.term='manmade features';
INSERT INTO l_scheme_term_parent SELECT 162, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='reservoirs' AND T2.term='hydrographic structures';
INSERT INTO l_scheme_term_parent SELECT 163, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='residential sites' AND T2.term='buildings';
INSERT INTO l_scheme_term_parent SELECT 164, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='ridges' AND T2.term='mountains';
INSERT INTO l_scheme_term_parent SELECT 165, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='rift zones' AND T2.term='faults';
INSERT INTO l_scheme_term_parent SELECT 166, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='rivers' AND T2.term='streams';
INSERT INTO l_scheme_term_parent SELECT 167, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='roadways' AND T2.term='transportation features';
INSERT INTO l_scheme_term_parent SELECT 168, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='school districts' AND T2.term='administrative areas';
INSERT INTO l_scheme_term_parent SELECT 169, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='seafloor features' AND T2.term='physiographic features';
INSERT INTO l_scheme_term_parent SELECT 170, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='seamounts' AND T2.term='seafloor features';
INSERT INTO l_scheme_term_parent SELECT 171, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='seaplane bases' AND T2.term='airport features';
INSERT INTO l_scheme_term_parent SELECT 172, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='seas' AND T2.term='hydrographic features';
INSERT INTO l_scheme_term_parent SELECT 173, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='shrublands' AND T2.term='biogeographic regions';
INSERT INTO l_scheme_term_parent SELECT 174, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='snow regions' AND T2.term='biogeographic regions';
INSERT INTO l_scheme_term_parent SELECT 175, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='sports facilities' AND T2.term='recreational facilities';
INSERT INTO l_scheme_term_parent SELECT 176, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='springs (hydrographic)' AND T2.term='streams';
INSERT INTO l_scheme_term_parent SELECT 177, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='statistical areas' AND T2.term='administrative areas';
INSERT INTO l_scheme_term_parent SELECT 178, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='storage basins' AND T2.term='basins';
INSERT INTO l_scheme_term_parent SELECT 179, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='storage structures' AND T2.term='manmade features';
INSERT INTO l_scheme_term_parent SELECT 180, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='streams' AND T2.term='hydrographic features';
INSERT INTO l_scheme_term_parent SELECT 181, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='subcontinents' AND T2.term='land regions';
INSERT INTO l_scheme_term_parent SELECT 182, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='submarine canyons' AND T2.term='seafloor features';
INSERT INTO l_scheme_term_parent SELECT 183, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='synclines' AND T2.term='folds (geologic)';
INSERT INTO l_scheme_term_parent SELECT 184, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='tectonic features' AND T2.term='physiographic features';
INSERT INTO l_scheme_term_parent SELECT 185, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='telecommunication features' AND T2.term='manmade features';
INSERT INTO l_scheme_term_parent SELECT 186, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='territorial waters' AND T2.term='administrative areas';
INSERT INTO l_scheme_term_parent SELECT 187, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='thermal features' AND T2.term='hydrographic features';
INSERT INTO l_scheme_term_parent SELECT 188, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='towers' AND T2.term='manmade features';
INSERT INTO l_scheme_term_parent SELECT 189, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='trails' AND T2.term='transportation features';
INSERT INTO l_scheme_term_parent SELECT 190, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='transportation features' AND T2.term='manmade features';
INSERT INTO l_scheme_term_parent SELECT 191, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='tribal areas' AND T2.term='administrative areas';
INSERT INTO l_scheme_term_parent SELECT 192, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='tundras' AND T2.term='biogeographic regions';
INSERT INTO l_scheme_term_parent SELECT 193, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='tunnels' AND T2.term='transportation features';
INSERT INTO l_scheme_term_parent SELECT 194, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='UTM zones' AND T2.term='map regions';
INSERT INTO l_scheme_term_parent SELECT 195, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='valleys' AND T2.term='physiographic features';
INSERT INTO l_scheme_term_parent SELECT 196, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='viewing locations' AND T2.term='parks';
INSERT INTO l_scheme_term_parent SELECT 197, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='volcanic features' AND T2.term='physiographic features';
INSERT INTO l_scheme_term_parent SELECT 198, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='volcanoes' AND T2.term='volcanic features';
INSERT INTO l_scheme_term_parent SELECT 199, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='waterfalls' AND T2.term='rivers';
INSERT INTO l_scheme_term_parent SELECT 200, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='waterworks' AND T2.term='hydrographic structures';
INSERT INTO l_scheme_term_parent SELECT 201, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='wells' AND T2.term='manmade features';
INSERT INTO l_scheme_term_parent SELECT 202, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='wetlands' AND T2.term='biogeographic regions';
INSERT INTO l_scheme_term_parent SELECT 203, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='windmills' AND T2.term='manmade features';
INSERT INTO l_scheme_term_parent SELECT 204, T1.scheme_term_id, T2.scheme_term_id FROM l_scheme_term T1, l_scheme_term T2 WHERE T1.term='woods' AND T2.term='forests';

INSERT INTO l_scheme_term VALUES (1263,2,'related to',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1264,2,'distinguished from',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1265,2,'adjacent to',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1266,2,'coextensive with',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1267,2,'ally of',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1268,2,'member of',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1269,2,'member is',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1270,2,'moved from',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1271,2,'moved to',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1272,2,'successor of',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1273,2,'predecessor of',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1274,2,'historical connection',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1275,2,'possibly identified as',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1276,2,'possibly equivalent to',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1277,2,'parent of',NULL,NULL,NULL);
INSERT INTO l_scheme_term VALUES (1278,2,'child of',NULL,NULL,NULL);

INSERT INTO l_scheme_term VALUES (1279,3,'undefined',NULL,NULL,NULL);

INSERT INTO l_time_period_name VALUES (1,'undefined',4,NULL);
INSERT INTO l_time_period_name VALUES (2,'undefined-current',4,NULL);
INSERT INTO l_time_period_name VALUES (3,'undefined-historical',4,NULL);
INSERT INTO l_time_period_name VALUES (4,'classical antiquity',4,NULL);
INSERT INTO l_time_period_name VALUES (5,'late antiquity',4,NULL);
INSERT INTO l_time_period_name VALUES (6,'middle ages',4,NULL);
INSERT INTO l_time_period_name VALUES (7,'byzantine era',4,NULL);
INSERT INTO l_time_period_name VALUES (8,'early middle ages',4,NULL);
INSERT INTO l_time_period_name VALUES (9,'dark ages',4,NULL);
INSERT INTO l_time_period_name VALUES (10,'viking age',4,NULL);
INSERT INTO l_time_period_name VALUES (11,'high middle ages',4,NULL);
INSERT INTO l_time_period_name VALUES (12,'late middle ages',4,NULL);
INSERT INTO l_time_period_name VALUES (13,'the renaissance',4,NULL);
INSERT INTO l_time_period_name VALUES (14,'early modern period',4,NULL);
INSERT INTO l_time_period_name VALUES (15,'age of discovery',4,NULL);
INSERT INTO l_time_period_name VALUES (16,'polish golden age',4,NULL);
INSERT INTO l_time_period_name VALUES (17,'golden age of piracy',4,NULL);
INSERT INTO l_time_period_name VALUES (18,'protestant reformation',4,NULL);
INSERT INTO l_time_period_name VALUES (19,'classicism',4,NULL);
INSERT INTO l_time_period_name VALUES (20,'industrious revolution',4,NULL);
INSERT INTO l_time_period_name VALUES (21,'age of enlightenment',4,NULL);
INSERT INTO l_time_period_name VALUES (22,'long nineteenth century',4,NULL);
INSERT INTO l_time_period_name VALUES (23,'romantic era',4,NULL);
INSERT INTO l_time_period_name VALUES (24,'napoleonic era',4,NULL);
INSERT INTO l_time_period_name VALUES (25,'first and second world wars',4,NULL);
INSERT INTO l_time_period_name VALUES (26,'cold war',4,NULL);
INSERT INTO l_time_period_name VALUES (27,'classic mesoamerica',4,NULL);
INSERT INTO l_time_period_name VALUES (28,'post-classic mesoamerica',4,NULL);
INSERT INTO l_time_period_name VALUES (29,'conquest of america',4,NULL);
INSERT INTO l_time_period_name VALUES (30,'mesoamerican colonial period',4,NULL);

INSERT INTO g_time_date_range VALUES (4,'-480-01-01','-476-01-01','classical antiquity',5);
INSERT INTO g_time_date_range VALUES (5,'0284-01-01','0500-01-01','late antiquity',5);
INSERT INTO g_time_date_range VALUES (6,'0476-01-01','1453-01-01','middle ages',5);
INSERT INTO g_time_date_range VALUES (7,'0330-01-01','1453-01-01','byzantine era',5);
INSERT INTO g_time_date_range VALUES (8,'0476-01-01','1066-01-01','early middle ages',5);
INSERT INTO g_time_date_range VALUES (9,'0476-01-01','0800-01-01','dark ages',5);
INSERT INTO g_time_date_range VALUES (10,'0793-01-01','1066-01-01','viking age',5);
INSERT INTO g_time_date_range VALUES (11,'1066-01-01','1300-01-01','high middle ages',5);
INSERT INTO g_time_date_range VALUES (12,'1300-01-01','1453-01-01','late middle ages',5);
INSERT INTO g_time_date_range VALUES (13,'1300-01-01','1600-01-01','the renaissance',5);
INSERT INTO g_time_date_range VALUES (14,'1453-01-01','1789-01-01','early modern period',5);
INSERT INTO g_time_date_range VALUES (15,'1400-01-01','1770-01-01','age of discovery (or exploration)',5);
INSERT INTO g_time_date_range VALUES (16,'1507-01-01','1572-01-01','polish golden age',5);
INSERT INTO g_time_date_range VALUES (17,'1650-01-01','1730-01-01','golden age of piracy',5);
INSERT INTO g_time_date_range VALUES (18,'1501-01-01','1600-12-31','protestant reformation',5);
INSERT INTO g_time_date_range VALUES (19,'1501-01-01','1800-12-31','classicism',5);
INSERT INTO g_time_date_range VALUES (20,'1501-01-01','1800-12-31','industrious revolution',5);
INSERT INTO g_time_date_range VALUES (21,'1701-01-01','1800-12-31','age of enlightenment',5);
INSERT INTO g_time_date_range VALUES (22,'1789-01-01','1914-01-01','long nineteenth century',5);
INSERT INTO g_time_date_range VALUES (23,'1770-01-01','1850-01-01','romantic era',5);
INSERT INTO g_time_date_range VALUES (24,'1770-01-01','1850-01-01','napoleonic era',5);
INSERT INTO g_time_date_range VALUES (25,'1914-01-01','1945-01-01','first and second world wars',5);
INSERT INTO g_time_date_range VALUES (26,'1945-01-01','1991-01-01','cold war',5);
INSERT INTO g_time_date_range VALUES (27,'0250-01-01','0900-01-01','classic mesoamerica',5);
INSERT INTO g_time_date_range VALUES (28,'0900-01-01','1521-01-01','post-classic mesoamerica',5);
INSERT INTO g_time_date_range VALUES (29,'1945-01-01','1991-01-01','conquest of america',5);
INSERT INTO g_time_date_range VALUES (30,'1521-01-01','1821-01-01','mesoamerican colonial period',5);

INSERT INTO g_time_period VALUES (4,1279);
INSERT INTO g_time_period VALUES (5,1279);
INSERT INTO g_time_period VALUES (6,1279);
INSERT INTO g_time_period VALUES (7,7);
INSERT INTO g_time_period VALUES (8,8);
INSERT INTO g_time_period VALUES (9,9);
INSERT INTO g_time_period VALUES (10,10);
INSERT INTO g_time_period VALUES (11,11);
INSERT INTO g_time_period VALUES (12,12);
INSERT INTO g_time_period VALUES (13,13);
INSERT INTO g_time_period VALUES (14,14);
INSERT INTO g_time_period_to_period_name VALUES (15,15);
INSERT INTO g_time_period_to_period_name VALUES (16,16);
INSERT INTO g_time_period_to_period_name VALUES (17,17);
INSERT INTO g_time_period_to_period_name VALUES (18,18);
INSERT INTO g_time_period_to_period_name VALUES (19,19);
INSERT INTO g_time_period_to_period_name VALUES (20,20);
INSERT INTO g_time_period_to_period_name VALUES (21,21);
INSERT INTO g_time_period_to_period_name VALUES (22,22);
INSERT INTO g_time_period_to_period_name VALUES (23,23);
INSERT INTO g_time_period_to_period_name VALUES (24,24);
INSERT INTO g_time_period_to_period_name VALUES (25,25);
INSERT INTO g_time_period_to_period_name VALUES (26,26);
INSERT INTO g_time_period_to_period_name VALUES (27,27);
INSERT INTO g_time_period_to_period_name VALUES (28,28);
INSERT INTO g_time_period_to_period_name VALUES (29,29);
INSERT INTO g_time_period_to_period_name VALUES (30,30);

INSERT INTO g_time_period_to_period_name VALUES (4,4);
INSERT INTO g_time_period_to_period_name VALUES (5,5);
INSERT INTO g_time_period_to_period_name VALUES (6,6);
INSERT INTO g_time_period_to_period_name VALUES (7,7);
INSERT INTO g_time_period_to_period_name VALUES (8,8);
INSERT INTO g_time_period_to_period_name VALUES (9,9);
INSERT INTO g_time_period_to_period_name VALUES (10,10);
INSERT INTO g_time_period_to_period_name VALUES (11,11);
INSERT INTO g_time_period_to_period_name VALUES (12,12);
INSERT INTO g_time_period_to_period_name VALUES (13,13);
INSERT INTO g_time_period_to_period_name VALUES (14,14);
INSERT INTO g_time_period_to_period_name VALUES (15,15);
INSERT INTO g_time_period_to_period_name VALUES (16,16);
INSERT INTO g_time_period_to_period_name VALUES (17,17);
INSERT INTO g_time_period_to_period_name VALUES (18,18);
INSERT INTO g_time_period_to_period_name VALUES (19,19);
INSERT INTO g_time_period_to_period_name VALUES (20,20);
INSERT INTO g_time_period_to_period_name VALUES (21,21);
INSERT INTO g_time_period_to_period_name VALUES (22,22);
INSERT INTO g_time_period_to_period_name VALUES (23,23);
INSERT INTO g_time_period_to_period_name VALUES (24,24);
INSERT INTO g_time_period_to_period_name VALUES (25,25);
INSERT INTO g_time_period_to_period_name VALUES (26,26);
INSERT INTO g_time_period_to_period_name VALUES (27,27);
INSERT INTO g_time_period_to_period_name VALUES (28,28);
INSERT INTO g_time_period_to_period_name VALUES (29,29);
INSERT INTO g_time_period_to_period_name VALUES (30,30);
