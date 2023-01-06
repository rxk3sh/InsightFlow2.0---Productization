({
    drawChart: function (component, helper) {
        helper.pieDonutChart(component, helper);
        component.set('v.chartRendered', true);
    },
    pieDonutChart: function (component, helper) {
        component.set('v.displayAxis', false);
        var total = d3.sum(component.get('v.data').map(function (d) {
            return d.value;
        }));
        
        var divContainer = d3.select(component.find('chart').getElement());
        var chartWidth = component.get('v.containerWidth')/1.35;
        var chartHeight = helper.getHeight(chartWidth);
        
        var size = chartWidth * .46;
        var radius = size / 2.5; //size / 2;
        var colors = helper.getColors();
        
        var svg = divContainer.append('svg')
        .attr('width', chartWidth)
        .attr('height', chartHeight)
        .attr('class', 'overflow-visible')
        
        var parentGrouping = svg.append('g')
        .attr('id', 'parentGroup')
        
        var donutWidth = size * .2;
        var arc = d3.arc()
        .innerRadius(0)
        .outerRadius(radius);
        
        var pie = d3.pie()
        .value(function (d) {
            return d.value;
        })
        .sort(null);
        
        var path = parentGrouping.selectAll('g')
        .data(pie(component.get('v.data')))
        .enter()
        .append('path')
        .attr('class', 'sc-section')
        .attr('d', arc)
        .attr('fill', function (d, i) {
            var colours = component.get("v.mapReqColors");
            if(colours !== undefined && colours !== null) {
                var reqColor = JSON.stringify(component.get("v.mapReqColors"));
                var jsonColor = JSON.parse(reqColor);
                if(jsonColor[d.data.segment] !== undefined) {
                    return jsonColor[d.data.segment];
                } else {
                    return colors(d.data.segment);
                }
            } else {
                return colors(d.data.segment);
            }
        });
        
        path.on('mouseover', $A.getCallback(function (dataPoint) {
            var percent = Math.round(1000 * dataPoint.data.value / total) / 10;
            
            var tooltipHtml = '<span class="sc-axis-label">' + component.get('v.segmentLabel') + ': </span><span class="sc-axis-value">' + dataPoint.data.segment + '</span><br/>' +
                '<span class="sc-axis-label">' + component.get('v.valueLabel') + ': </span><span class="sc-axis-value">' + helper.abbreviateNumber(dataPoint.data.value) + '</span><br/>' +
                '<span class="sc-pdc-section-percent">' + percent + '% of ' + helper.abbreviateNumber(total) + '</span>';
            
            component.set('v.tooltipHtml', tooltipHtml);
        }));
        
        path.on('mouseout', $A.getCallback(function () {
            helper.hideTooltip(component);
        }));
        
        path.on('mousemove', $A.getCallback(function () {
            var mousePos = d3.mouse(component.find('chartContainer').getElement());
            
            var tooltipOptions = {
                x: mousePos[0]+10,
                y: mousePos[1]+10,
                chartWidth: chartWidth
            }
            // handles the tooltip on pie chart
            helper.showToolTip(component, tooltipOptions); 
        }));
        
        var legendCircleRadius = size * .03;
        var legendSpacing = size * .04;
        var legendGrouping = parentGrouping.append('g');
        var legend = legendGrouping.selectAll('.sc-pdc-legend')
        .data(pie(component.get('v.data')))
        .enter()
        .append('g')
        .attr('class', 'sc-pdc-legend')
        .attr('transform', function (d, i) {
            var legendRectHeight = 2 * legendCircleRadius;
            var legendRectOffset = i * (legendRectHeight + legendSpacing);
            return 'translate(0,' + legendRectOffset + ')';
        })
        .attr('style', $A.getCallback(function (d, i) {
            if(d !== undefined && d.data !== undefined) {
                if(component.get("v.index") === d.data.developerName) {
                    return 'font-weight: bold;';
                }
            }
        }));
        
        var getCircleColor = function (d) {
            var colours = component.get("v.mapReqColors");
            if(colours !== undefined && colours !== null) {
                var reqColor = JSON.stringify(component.get("v.mapReqColors"));
                var jsonColor = JSON.parse(reqColor);
                if(jsonColor[d.data.segment] !== undefined) {
                    return jsonColor[d.data.segment];
                } else {
                    return colors(d.data.segment);
                }
            } else {
                return colors(d.data.segment);
            }
        }
        
        var circleParams = {
            parent: legend,
            circleX: -11,
            circleY: -legendCircleRadius / 2,
            radius: legendCircleRadius,
            cssClass: '',
            fill: getCircleColor,
            stroke: '',
            strokeWidth: 0
        }
        
        helper.addCircle(circleParams);
        var getLabel = function (d) {
            var label = d.data.segment;
            if(label) {
                return label + ' - ' + d.data.value;
            } else {
                return;
            }
            
        }
        var legendLabelParams = {
            parent: legend,
            cssClass: '',
            rotation: 0,
            x: legendCircleRadius - 6,
            y: 0,
            fontSize: size * .05,
            textAnchor: '',
            label: getLabel
        }
        
        helper.addLabel(legendLabelParams);
        
        if(legendGrouping !== undefined) {
            if(legendGrouping._groups[0][0] !== undefined) {
                var legendBoundingBox;
                try {
                    legendBoundingBox = legendGrouping._groups[0][0].getBBox();
                } catch(error) {
                    if(error.name !== undefined && error.message !== undefined) {
                        console.error(error.name + ", " + error.message);
                    }
                }
                if(legendBoundingBox !== undefined) {
                    var legendPaddingSpace = radius * .33
                    var legendX = radius + legendPaddingSpace + 20;
                    var legendCenterY = legendCircleRadius - legendBoundingBox.height / 2;
                    legendGrouping.attr('transform', 'translate(' + legendX + ', ' + legendCenterY + ')');
                    
                    legend.on('click', $A.getCallback(function (dataPoint) {
                        legend.attr('style', $A.getCallback(function (d, i) {
                            if(d !== undefined && d.data !== undefined) {
                                if(dataPoint.data.developerName === d.data.developerName) {
                                    return 'font-weight: bold;';
                                }
                            }
                        }));
                        var cmpEvent = component.getEvent("requestStatus"); 
                        var selected = JSON.parse(JSON.stringify(dataPoint.data.developerName));
                        cmpEvent.setParams({"status" : selected}); 
                        cmpEvent.fire();
                    }));
                    
                    var parentGroupingWidth = parentGrouping._groups[0][0].getBBox().width;
                    var parentGroupingHeight = parentGrouping._groups[0][0].getBBox().height;
                    var centeredX = Math.ceil(((chartWidth - parentGroupingWidth) / 2) + radius) + 10;
                    var centeredY = Math.ceil(((chartHeight - parentGroupingHeight) / 2) + radius);
                    
                    parentGrouping.attr('transform', 'translate(' + centeredX + ',' + centeredY + ')');
                }
            }
        }
    },
    getHeight: function (basedOnWidth) {
        return basedOnWidth * .5;
    },
    addCircle: function (circleParams) {
        return circleParams.parent.append('circle')
        .attr('cx', circleParams.circleX)
        .attr('cy', circleParams.circleY)
        .attr('r', circleParams.radius)
        .attr('class', circleParams.cssClass)
        .style('fill', circleParams.fill)
        .style('stroke', circleParams.stroke)
        .style('stroke-width', circleParams.strokeWidth)
    },
    addLabel: function (labelParams) {
        var label = labelParams.parent.append('text')
        .attr('class', labelParams.cssClass)
        .attr('text-anchor', labelParams.textAnchor)
        .attr('transform', 'rotate(' + labelParams.rotation + ')')
        .attr('x', labelParams.x)
        .attr('y', labelParams.y)
        .attr('font-size', labelParams.fontSize)
        .attr('dy', '0em')
        .style("cursor", "pointer")
        .text(labelParams.label);
        
        if (labelParams.fill !== undefined) label.attr('fill', labelParams.fill);
        return label;
    },
    abbreviateNumber: function (amount) {
        var absAmount = Math.abs(Number(amount));
        var amountNumber = Number(amount);
        var shortenedNumber = amountNumber;
        var abbreviation = '';
        var trillion = Math.pow(10, 12);
        var billion = Math.pow(10, 9);
        var million = Math.pow(10, 6);
        var thousand = Math.pow(10, 3);
        
        if (absAmount / trillion >= 1) {
            shortenedNumber = amountNumber / trillion;
            abbreviation = 'T';
            
        } else if (absAmount / billion >= 1) {
            shortenedNumber = amountNumber / billion;
            abbreviation = 'B';
            
        } else if (absAmount / million >= 1) {
            shortenedNumber = amountNumber / million;
            abbreviation = 'M';
            
        } else if (absAmount / thousand >= 1) {
            shortenedNumber = amountNumber / thousand;
            abbreviation = 'K';
        }
        
        return (parseFloat(shortenedNumber.toFixed(1)) + abbreviation);
    },
    hideTooltip: function (component) {
        component.set('v.tooltipOpacity', 0);
        component.set('v.tooltipDisplay', 'none')
    },
    showToolTip: function (component, tooltipOptions) {
        var tooltipElement = component.find('tooltipContainer').getElement()
        var tooltipElementCopy = component.find('tooltipContainerCopy').getElement();
        var tooltipOffSet = 10;
        
        var tooltipXPos = tooltipOptions.x + tooltipOffSet + 10;
        var tooltipYPos = tooltipOptions.y + tooltipOffSet + 10;
        
        if ((tooltipElementCopy.clientWidth + tooltipXPos) > tooltipOptions.chartWidth) {
            tooltipXPos -= (tooltipElementCopy.clientWidth + (tooltipOffSet * 2));
            
            if (tooltipXPos < 0) {
                tooltipXPos = tooltipOptions.x + tooltipOffSet;
            }
        }
        
        component.set('v.tooltipDisplay', 'block');
        component.set('v.tooltipXPos', tooltipXPos);
        component.set('v.tooltipYPos', tooltipYPos);
        component.set('v.tooltipOpacity', 1);
    },
    determineFontSize: function (chartWidth) {
        var fontSize = '.8125rem';
        
        if (chartWidth < 767) {
            fontSize = '.625rem';
        } else if (chartWidth < 1023) {
            fontSize = '.75rem';
        }
        
        return fontSize;
    },
    getColors: function () {
        return d3.scaleOrdinal().range([$A.get("$Label.c.CLIFv20095"), $A.get("$Label.c.CLIFv20096"), $A.get("$Label.c.CLIFv20097"), $A.get("$Label.c.CLIFv20098"), $A.get("$Label.c.CLIFv20099"),
                                        $A.get("$Label.c.CLIFv20100"), $A.get("$Label.c.CLIFv20101"), $A.get("$Label.c.CLIFv20102"), $A.get("$Label.c.CLIFv20103"), $A.get("$Label.c.CLIFv20104"), $A.get("$Label.c.CLIFv20105"), $A.get("$Label.c.CLIFv20106")
                                       ]);
    }
})