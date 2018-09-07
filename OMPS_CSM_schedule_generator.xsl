<?xml version='1.0' encoding='UTF-8'?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
	<xsl:output method="xml" version="1.0" omit-xml-declaration="no" encoding="UTF-8" indent="no"	/>
	<xsl:template match="Root">          
		<xsl:variable name="CBMCount" select="count(/Root/CBM)" />
		<xsl:if test="$CBMCount > 0">
			<eventList>
				<xsl:for-each select="/Root/CBM">
					<event>
						<id><xsl:value-of select="@id"/></id>
						<description/>
						<startTime><xsl:value-of select="@StartTime"/></startTime>
						<stopTime><xsl:value-of select="@StopTime"/></stopTime>
						<eventResources>
							<eventResource>
								<eventId><xsl:value-of select="@id"/></eventId>
								<resourceName><xsl:value-of select="@resource0"/></resourceName>
								<displayOrder>0</displayOrder>
							</eventResource>
							<eventResource>
								<eventId><xsl:value-of select="@id"/></eventId>
								<resourceName><xsl:value-of select="@resource1"/></resourceName>
								<displayOrder>1</displayOrder>
							</eventResource>
							<eventResource>
								<eventId><xsl:value-of select="@id"/></eventId>
								<resourceName><xsl:value-of select="@resource2"/></resourceName>
								<displayOrder>2</displayOrder>
							</eventResource>
						</eventResources>
						<eventParams>
							<eventParam>
								<eventId><xsl:value-of select="@id"/></eventId>
								<key>EVENT_START_REV</key>
								<value>1</value>
							</eventParam>
							<eventParam>
								<eventId><xsl:value-of select="@id"/></eventId>
								<key>EVENT_STOP_REV</key>
								<value>1</value>
							</eventParam>
						</eventParams>
					</event>
				</xsl:for-each>
			</eventList>
		</xsl:if>
	</xsl:template>
</xsl:stylesheet>
