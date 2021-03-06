### =========================================================================
### Epigenome Objects 
### -------------------------------------------------------------------------
###

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### EpiMetadata, EpiExpression, EpichmmModel Objects
###

setClass("EpiMetadataResource", contains="AnnotationHubResource")

setMethod(".get1", "EpiMetadataResource",
   function(x, ...)
{
    read.delim(cache(getHub(x)))
})

setClass("EpiExpressionTextResource", contains="AnnotationHubResource")

setMethod(".get1", "EpiExpressionTextResource",
    function(x, ...)
{
    yy <- cache(getHub(x))
    data <- read.table(yy, header=TRUE, row.names=1)
    if(grepl("chr" ,rownames(data)[1])){
       .require("SummarizedExperiment")
       data <- SummarizedExperiment::SummarizedExperiment(
           assays=as.matrix(data[,-c(1:2)]), 
           rowRanges=.makeGrFromCharacterString(data))
    }
    data 
})

setClass("EpichmmModelsResource", contains="AnnotationHubResource")

setMethod(".get1", "EpichmmModelsResource",
    function(x, ...)
{
    .require("rtracklayer")
    yy <- getHub(x)
    gr <- rtracklayer::import(cache(yy), format="bed", genome="hg19")
    gr <- .mapAbbr2FullName(gr)
    .tidyGRanges(x, gr)
 
})

## helper function which changes 'chr10:100011323-100011459<-1' to gr!
.makeGrFromCharacterString <- function(data) {
    nms = sub("<-*1", "", rownames(data)) 
    lst = strsplit(nms, "[:-]") 
    v = function(x, i) vapply(x, "[[", "character", i)
    gr = GenomicRanges::GRanges(v(lst, 1), 
       IRanges::IRanges(as.integer(v(lst, 2)), as.integer(v(lst, 3))))
    mcols(gr) = data[,1:2]
    gr
}


## this data is got from :
## chromhmmSegmentations/ChmmModels/coreMarks/jointModel/final/labelmap_15_coreMarks.tab
## chromhmmSegmentations/ChmmModels/coreMarks/jointModel/final/colormap_15_coreMarks.tab
## the bed file has abbr - and these 3 columns are helpful for collaborators.
.mapAbbr2FullName <- function(gr) {
    map <- as.data.frame(matrix(c(
        "1_TssA", "Active TSS", "Red", rgb(255,0,0, maxColorValue=255),
        "2_TssAFlnk", "Flanking Active TSS", "Orange Red", rgb(255,69,0, 
             maxColorValue=255),
        "3_TxFlnk", "Transcr. at gene 5' and 3'", "LimeGreen", rgb(50,205,50, 
             maxColorValue=255),
        "4_Tx", "Strong transcription", "Green", rgb(0,128,0, 
             maxColorValue=255),
        "5_TxWk", "Weak transcription", "DarkGreen", rgb(0,100,0, 
             maxColorValue=255),
        "6_EnhG", "Genic enhancers", "GreenYellow", rgb(194,225,5, 
             maxColorValue=255),
        "7_Enh", "Enhancers", "Yellow", rgb(255,255,0, 
             maxColorValue=255),
        "8_ZNF/Rpts", "ZNF genes & repeats", "Medium Aquamarine", 
             rgb(102,205,170, maxColorValue=255),
        "9_Het", "Heterochromatin", "PaleTurquoise", rgb(138,145,208, 
             maxColorValue=255),
        "10_TssBiv", "Bivalent/Poised TSS", "IndianRed", 
             rgb(205,92,92, maxColorValue=255),
        "11_BivFlnk", "Flanking Bivalent TSS/Enh", "DarkSalmon", 
             rgb(233,150,122, maxColorValue=255),
        "12_EnhBiv", "Bivalent Enhancer", "DarkKhaki", 
             rgb(189,183,107, maxColorValue=255),
        "13_ReprPC", "Repressed PolyComb", "Silver", 
             rgb(128,128,128, maxColorValue=255),
        "14_ReprPCWk", "Weak Repressed PolyComb", "Gainsboro", 
             rgb(192,192,192, maxColorValue=255),
        "15_Quies", "Quiescent/Low", "White", rgb(255,255,255, maxColorValue=255)), 
             byrow=TRUE, nrow=15), stringsAsFactors=FALSE)
    colnames(map) <- c("abbr", "name", "color_name", "color_code")

    ##perform the mapping
    toMatch <- mcols(gr)$name
    newdf <- map[match(toMatch, map$abbr),]
    mcols(gr) <- newdf
    gr
}
### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### EpigenomeRoadmap* Objects
###

### These classes are similar to the UCSCBroadPeak, UCSCNarrowPeak, family.
### The individual methods add 'extraCols' then dispatch through 
### BEDFileResource. 

setClass("EpigenomeRoadmapFileResource", contains="AnnotationHubResource")

## NOTE: This dispatch class encompasses both broad and narrow peak -
##       (Precursors were UCSCNarrowPeak and UCSCBroadPeak?)
setMethod(".get1", "EpigenomeRoadmapFileResource",
    function(x, ...)
{
    .require("rtracklayer")
    yy <- getHub(x)
    extraCols=c(signalValue="numeric", pValue="numeric", qValue="numeric")
    if (grepl("narrow", yy$sourceurl))
        extraCols=c(extraCols, peak="numeric")
    gr <- rtracklayer::import(cache(yy), format="bed", genome=yy$genome,
                              extraCols=extraCols)
    .tidyGRanges(x, gr)
})
setClass("EpigenomeRoadmapNarrowAllPeaksResource", 
         contains="BEDFileResource")

setMethod(".get1", "EpigenomeRoadmapNarrowAllPeaksResource",
    function(x, ...)
{
    narrowAllPeaks <- c(peakTagDensity="numeric")
    callNextMethod(x, extraCols=narrowAllPeaks)
})

setClass("EpigenomeRoadmapNarrowFDRResource", 
         contains="BEDFileResource")

setMethod(".get1", "EpigenomeRoadmapNarrowFDRResource",
    function(x, ...)
{
    narrowFDR <- c(peakTagDensity="numeric", zScore="numeric")
    callNextMethod(x, extraCols=narrowFDR)
})
