const healthCheck = (req, res) => {
  const timeStamp = new Date().toISOString();
  res.status(200).json({ status: "OK", timeStamp });
};

export default healthCheck;
