# models.py
from sqlalchemy import Column, String, DateTime, Integer, ForeignKey, Text
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from db.db import Base

class Job(Base):
    __tablename__ = "jobs"
    id = Column(String, primary_key=True, index=True)   # uuid string
    status = Column(String, default="pending", index=True)
    start_time = Column(DateTime(timezone=True), server_default=func.now())
    end_time = Column(DateTime(timezone=True), nullable=True)
    message = Column(Text, nullable=True)

    files = relationship("JobFile", back_populates="job", cascade="all, delete-orphan")


class JobFile(Base):
    __tablename__ = "job_files"
    id = Column(Integer, primary_key=True, autoincrement=True)
    job_id = Column(String, ForeignKey("jobs.id"), index=True)
    file_type = Column(String, index=True)  # ex: "uploaded", "wav", "vocals", "ass", "final"
    path = Column(Text)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    job = relationship("Job", back_populates="files")
