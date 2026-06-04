import PDFParser from "pdf2json";

export const extractTextFromPDF = (filePath) => {
  return new Promise((resolve, reject) => {
    // Pass 1 to extract raw text
    const pdfParser = new PDFParser(null, 1);

    pdfParser.on("pdfParser_dataError", (errData) => {
      console.error("PDF Parsing Error:", errData.parserError);
      reject(errData.parserError);
    });

    pdfParser.on("pdfParser_dataReady", () => {
      // getRawTextContent() returns the text safely
      const text = pdfParser.getRawTextContent();
      resolve(text);
    });

    pdfParser.loadPDF(filePath);
  });
};